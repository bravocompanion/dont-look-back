extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const WILDLIFE_SCRIPT_PATH: String = "res://scripts/wildlife_animal.gd"
const FISHING_SCRIPT_PATH: String = "res://scripts/fishing_spot.gd"
const CACHE_SCRIPT_PATH: String = "res://scripts/forest_supply_cache.gd"
const COOKING_SCRIPT_PATH: String = "res://scripts/forest_cooking_station.gd"
const SHELTER_CENTER: Vector3 = Vector3(14.0, 0.92, -82.0)

@export var weather_min_seconds: float = 75.0
@export var weather_max_seconds: float = 145.0
@export var animal_respawn_seconds: float = 95.0
@export var bow_range: float = 38.0
@export var bow_damage: float = 1.0
@export var bow_cooldown_seconds: float = 0.78
@export var fishing_cooldown_seconds: float = 18.0

var configured_scene_id: int = 0
var outside_root: Node3D
var wildlife_script: Script
var fishing_script: Script
var cache_script: Script
var cooking_script: Script
var animals: Dictionary = {}
var animal_specs: Dictionary = {}
var respawn_timers: Dictionary = {}
var fishing_cooldowns: Dictionary = {}
var state_sync_timer: float = 0.0
var bow_cooldown: float = 0.0
var current_weather: String = "clear"
var weather_timer: float = 95.0
var wetness: float = 0.0
var weather_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var forest_active: bool = false

var ui_layer: CanvasLayer
var weather_tint: ColorRect
var weather_label: Label
var hunt_button: Button
var ui_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    wildlife_script = load(WILDLIFE_SCRIPT_PATH) as Script
    fishing_script = load(FISHING_SCRIPT_PATH) as Script
    cache_script = load(CACHE_SCRIPT_PATH) as Script
    cooking_script = load(COOKING_SCRIPT_PATH) as Script
    weather_rng.randomize()
    _build_ui()
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    bow_cooldown = maxf(0.0, bow_cooldown - delta)
    _tick_fishing_cooldowns(delta)

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        forest_active = false
        outside_root = null
        configured_scene_id = 0
        _set_ui_visible(false)
        return

    forest_active = true
    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        animals.clear()
        animal_specs.clear()
        respawn_timers.clear()
        outside_root = null
        call_deferred("_configure_forest", scene)

    var player: CharacterBody3D = _local_player()
    if player != null and not bool(player.get("is_dead")):
        _apply_weather_survival(player, delta)

    if _is_authoritative():
        weather_timer -= delta
        if weather_timer <= 0.0:
            _choose_next_weather()
        _tick_respawns(delta)
        state_sync_timer -= delta
        if state_sync_timer <= 0.0:
            state_sync_timer = 0.18
            _broadcast_wildlife_state()

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.20
        _update_ui(player)

func _unhandled_input(event: InputEvent) -> void:
    if not forest_active or bow_cooldown > 0.0 or _ui_blocked():
        return
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
            _try_hunt()
            get_viewport().set_input_as_handled()

func request_fishing(spot_id: String) -> void:
    if not forest_active or _ui_blocked():
        return
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "fishing_rod")):
        _objective(player, "You need the Fishing Rod from the ranger cache before fishing.")
        return

    var peer_id: int = _local_peer_id()
    if _network_online() and not _is_authoritative():
        _request_fishing_remote.rpc_id(1, spot_id)
    else:
        _resolve_fishing(peer_id, spot_id)

func on_animal_killed(animal_id: String, animal_kind: String, hunter_peer_id: int) -> void:
    if not _is_authoritative():
        return
    respawn_timers[animal_id] = animal_respawn_seconds
    var loot: Dictionary = _loot_for_kind(animal_kind)
    _grant_loot_to_peer(hunter_peer_id, loot, "HUNT: %s down. Harvested %s." % [animal_kind.capitalize(), _loot_summary(loot)])
    _broadcast_wildlife_state()

func report_wildlife_attack(player: CharacterBody3D, amount: float, animal_kind: String) -> void:
    if player == null or not _is_authoritative():
        return
    var source: String = "Wild Boar" if animal_kind == "boar" else "Wolf"
    if _network_online():
        var peer_id: int = player.get_multiplayer_authority()
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("damage_survivor") and peer_id > 0:
            coop.call("damage_survivor", peer_id, amount, source)
            return
    if player.has_method("apply_damage"):
        player.call("apply_damage", amount, source)

func _configure_forest(scene: Node) -> void:
    for _frame: int in range(12):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        outside_root = scene.get_node_or_null("OutsideWorld") as Node3D
        if outside_root != null:
            break
    if outside_root == null:
        return

    _spawn_equipment_cache()
    _spawn_cooking_station()
    _spawn_fishing_spots()
    _build_wildlife_specs()
    _spawn_wildlife()
    if _is_authoritative():
        _send_weather_state()
        _broadcast_wildlife_state()

func _spawn_equipment_cache() -> void:
    if cache_script == null or outside_root.has_node("RangerSurvivalCache"):
        return
    var cache: StaticBody3D = StaticBody3D.new()
    cache.name = "RangerSurvivalCache"
    cache.set_script(cache_script)
    cache.position = Vector3(10.9, 0.0, -80.1)
    outside_root.add_child(cache)

func _spawn_cooking_station() -> void:
    if cooking_script == null or outside_root.has_node("ForestCookingRack"):
        return
    var station: StaticBody3D = StaticBody3D.new()
    station.name = "ForestCookingRack"
    station.set_script(cooking_script)
    station.position = Vector3(12.6, 0.0, -74.5)
    outside_root.add_child(station)

func _spawn_fishing_spots() -> void:
    if fishing_script == null:
        return
    var spots: Array[Dictionary] = [
        {"id": "pond_a", "position": Vector3(35.0, 0.0, -188.0)},
        {"id": "pond_b", "position": Vector3(43.0, 0.0, -174.0)}
    ]
    for data: Dictionary in spots:
        var node_name: String = "FishingSpot_%s" % str(data.get("id", "x"))
        if outside_root.has_node(NodePath(node_name)):
            continue
        var spot: StaticBody3D = StaticBody3D.new()
        spot.name = node_name
        spot.set_script(fishing_script)
        spot.set("spot_id", str(data.get("id", "pond")))
        spot.position = Vector3(data.get("position", Vector3.ZERO))
        outside_root.add_child(spot)

func _build_wildlife_specs() -> void:
    animal_specs = {
        "deer_a": {"kind": "deer", "position": Vector3(-20.0, 0.0, -104.0)},
        "deer_b": {"kind": "deer", "position": Vector3(31.0, 0.0, -123.0)},
        "rabbit_a": {"kind": "rabbit", "position": Vector3(7.0, 0.0, -96.0)},
        "rabbit_b": {"kind": "rabbit", "position": Vector3(-33.0, 0.0, -139.0)},
        "rabbit_c": {"kind": "rabbit", "position": Vector3(38.0, 0.0, -151.0)},
        "boar_a": {"kind": "boar", "position": Vector3(-40.0, 0.0, -170.0)},
        "wolf_a": {"kind": "wolf", "position": Vector3(30.0, 0.0, -194.0)}
    }

func _spawn_wildlife() -> void:
    if wildlife_script == null or outside_root == null:
        return
    var remote: bool = _network_online() and not _is_authoritative()
    for id_value: Variant in animal_specs.keys():
        var animal_id: String = str(id_value)
        var data: Dictionary = Dictionary(animal_specs.get(animal_id, {}))
        var node_name: String = "Wildlife_%s" % animal_id
        var existing: CharacterBody3D = outside_root.get_node_or_null(NodePath(node_name)) as CharacterBody3D
        if existing != null:
            animals[animal_id] = existing
            continue
        var animal: CharacterBody3D = CharacterBody3D.new()
        animal.name = node_name
        animal.set_script(wildlife_script)
        outside_root.add_child(animal)
        if animal.has_method("configure"):
            animal.call("configure", animal_id, str(data.get("kind", "deer")), Vector3(data.get("position", Vector3.ZERO)), remote)
        animals[animal_id] = animal

func _try_hunt() -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "hunting_bow")):
        _objective(player, "You need the Hunting Bow from the ranger cache.")
        return
    if not bool(player.call("has_item", "arrow")):
        _objective(player, "No arrows left. Search containers or return to the ranger cache on a fresh run.")
        return
    if not player.has_method("remove_item") or not bool(player.call("remove_item", "arrow")):
        return

    bow_cooldown = bow_cooldown_seconds
    player.set("stamina", maxf(0.0, float(player.get("stamina")) - 4.0))
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var origin: Vector3 = camera.global_position
    var end: Vector3 = origin + (-camera.global_transform.basis.z.normalized()) * bow_range
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
    query.exclude = [player.get_rid()]
    var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
    if hit.is_empty():
        _objective(player, "The arrow vanishes between the trees.")
        return

    var animal: Node = _wildlife_from_collider(hit.get("collider", null))
    if animal == null:
        _objective(player, "The arrow strikes something that is not prey.")
        return

    var animal_id: String = str(animal.get("animal_id"))
    if _network_online() and not _is_authoritative():
        _request_hunt_remote.rpc_id(1, animal_id)
    elif animal.has_method("take_hunting_damage"):
        animal.call("take_hunting_damage", bow_damage, _local_peer_id())

func _wildlife_from_collider(value: Variant) -> Node:
    if not (value is Node):
        return null
    var current: Node = value as Node
    while current != null:
        if current.is_in_group("wildlife") and current.has_method("take_hunting_damage"):
            return current
        current = current.get_parent()
    return null

@rpc("any_peer", "call_remote", "reliable", 23)
func _request_hunt_remote(animal_id: String) -> void:
    if not _is_authoritative():
        return
    var sender: int = multiplayer.get_remote_sender_id()
    var animal: Node = animals.get(animal_id, null) as Node
    if animal != null and bool(animal.get("alive")) and animal.has_method("take_hunting_damage"):
        animal.call("take_hunting_damage", bow_damage, sender)

@rpc("any_peer", "call_remote", "reliable", 24)
func _request_fishing_remote(spot_id: String) -> void:
    if not _is_authoritative():
        return
    _resolve_fishing(multiplayer.get_remote_sender_id(), spot_id)

func _resolve_fishing(peer_id: int, _spot_id: String) -> void:
    var remaining: float = float(fishing_cooldowns.get(peer_id, 0.0))
    if remaining > 0.0:
        _message_peer(peer_id, "The water needs time to settle. Try fishing again in %d seconds." % int(ceil(remaining)))
        return
    fishing_cooldowns[peer_id] = fishing_cooldown_seconds

    var chance: float = 0.76
    if current_weather == "rain":
        chance = 0.88
    elif current_weather == "storm":
        chance = 0.58

    if weather_rng.randf() > chance:
        _message_peer(peer_id, "You wait, feel one pull on the line, then nothing. The fish got away.")
        return

    var count: int = 2 if weather_rng.randf() < 0.16 else 1
    var loot: Dictionary = {"raw_fish": count}
    _grant_loot_to_peer(peer_id, loot, "FISHING: caught %d freshwater fish. Cook it before eating." % count)

func _tick_fishing_cooldowns(delta: float) -> void:
    for peer_value: Variant in fishing_cooldowns.keys():
        var peer_id: int = int(peer_value)
        fishing_cooldowns[peer_id] = maxf(0.0, float(fishing_cooldowns.get(peer_id, 0.0)) - delta)

func _loot_for_kind(kind: String) -> Dictionary:
    match kind:
        "rabbit": return {"raw_meat": 1, "hide": 1}
        "boar": return {"raw_meat": 3, "hide": 1, "bone": 2, "animal_fat": 2}
        "wolf": return {"hide": 2, "bone": 2, "animal_fat": 1}
        _: return {"raw_meat": 4, "hide": 2, "bone": 2, "animal_fat": 1}

func _loot_summary(loot: Dictionary) -> String:
    var parts: PackedStringArray = PackedStringArray()
    for key: Variant in loot.keys():
        parts.append("%s x%d" % [_display_name(str(key)), int(loot.get(key, 0))])
    return ", ".join(parts)

func _grant_loot_to_peer(peer_id: int, loot: Dictionary, message: String) -> void:
    if not _network_online() or peer_id == _local_peer_id():
        _grant_loot_local(loot, message)
        return
    _grant_loot_remote.rpc_id(peer_id, loot, message)

@rpc("authority", "call_remote", "reliable", 25)
func _grant_loot_remote(loot: Dictionary, message: String) -> void:
    _grant_loot_local(loot, message)

func _grant_loot_local(loot: Dictionary, message: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("add_item"):
        return
    var lost: int = 0
    for id_value: Variant in loot.keys():
        var item_id: String = str(id_value)
        var count: int = int(loot.get(id_value, 0))
        for _index: int in range(count):
            if not bool(player.call("add_item", item_id, _display_name(item_id))):
                lost += 1
    _objective(player, message + (" Inventory full: %d item(s) left behind." % lost if lost > 0 else ""))

func _message_peer(peer_id: int, message: String) -> void:
    if not _network_online() or peer_id == _local_peer_id():
        var player: CharacterBody3D = _local_player()
        if player != null:
            _objective(player, message)
        return
    _receive_message_remote.rpc_id(peer_id, message)

@rpc("authority", "call_remote", "reliable", 26)
func _receive_message_remote(message: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player != null:
        _objective(player, message)

func _display_name(item_id: String) -> String:
    match item_id:
        "raw_meat": return "Raw Meat"
        "raw_fish": return "Raw Fish"
        "cooked_meat": return "Cooked Meat"
        "cooked_fish": return "Cooked Fish"
        "hide": return "Animal Hide"
        "bone": return "Bone"
        "animal_fat": return "Animal Fat"
        "arrow": return "Arrow"
        "hunting_bow": return "Hunting Bow"
        "fishing_rod": return "Fishing Rod"
    return item_id.replace("_", " ").capitalize()

func _choose_next_weather() -> void:
    var options: Array[String] = ["clear", "cloudy", "rain", "storm"]
    var weights: Array[float] = [0.34, 0.30, 0.26, 0.10]
    var roll: float = weather_rng.randf()
    var cursor: float = 0.0
    var selected: String = "clear"
    for index: int in range(options.size()):
        cursor += weights[index]
        if roll <= cursor:
            selected = options[index]
            break
    current_weather = selected
    weather_timer = weather_rng.randf_range(weather_min_seconds, weather_max_seconds)
    _send_weather_state()

func _send_weather_state() -> void:
    if _network_online() and _is_authoritative():
        _receive_weather_state.rpc(current_weather, weather_timer)

@rpc("authority", "call_remote", "reliable", 27)
func _receive_weather_state(weather: String, remaining: float) -> void:
    current_weather = weather
    weather_timer = remaining

func _apply_weather_survival(player: CharacterBody3D, delta: float) -> void:
    var sheltered: bool = player.global_position.distance_to(SHELTER_CENTER) <= 6.0
    if sheltered:
        wetness = maxf(0.0, wetness - 18.0 * delta)
    elif current_weather == "storm":
        wetness = minf(100.0, wetness + 7.5 * delta)
    elif current_weather == "rain":
        wetness = minf(100.0, wetness + 4.2 * delta)
    else:
        wetness = maxf(0.0, wetness - (2.0 if current_weather == "clear" else 0.8) * delta)

    if wetness >= 55.0:
        var stamina_loss: float = (0.24 if wetness < 82.0 else 0.48) * delta
        player.set("stamina", maxf(0.0, float(player.get("stamina")) - stamina_loss))

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null and not sheltered and wetness >= 65.0:
        var extra_cold: float = (0.55 if current_weather == "storm" else 0.25) * delta
        outside.set("cold_exposure", minf(100.0, float(outside.get("cold_exposure")) + extra_cold))

func _tick_respawns(delta: float) -> void:
    for id_value: Variant in respawn_timers.keys():
        var animal_id: String = str(id_value)
        var remaining: float = maxf(0.0, float(respawn_timers.get(animal_id, 0.0)) - delta)
        respawn_timers[animal_id] = remaining
        if remaining > 0.0:
            continue
        respawn_timers.erase(animal_id)
        var data: Dictionary = Dictionary(animal_specs.get(animal_id, {}))
        var animal: Node = animals.get(animal_id, null) as Node
        if animal != null and animal.has_method("reset_animal"):
            animal.call("reset_animal", Vector3(data.get("position", Vector3.ZERO)))

func _broadcast_wildlife_state() -> void:
    if not _network_online() or not _is_authoritative():
        return
    var state: Dictionary = {}
    for id_value: Variant in animals.keys():
        var animal_id: String = str(id_value)
        var animal: Node3D = animals.get(animal_id, null) as Node3D
        if animal == null:
            continue
        state[animal_id] = {
            "position": animal.global_position,
            "yaw": animal.rotation.y,
            "alive": bool(animal.get("alive")),
            "health": float(animal.get("current_health"))
        }
    _receive_wildlife_state.rpc(state)

@rpc("authority", "call_remote", "unreliable", 28)
func _receive_wildlife_state(state: Dictionary) -> void:
    if _is_authoritative():
        return
    for id_value: Variant in state.keys():
        var animal_id: String = str(id_value)
        var data: Dictionary = Dictionary(state.get(id_value, {}))
        var animal: Node = animals.get(animal_id, null) as Node
        if animal != null and animal.has_method("apply_remote_state"):
            animal.call(
                "apply_remote_state",
                Vector3(data.get("position", Vector3.ZERO)),
                float(data.get("yaw", 0.0)),
                bool(data.get("alive", true)),
                float(data.get("health", 1.0))
            )

func _on_peer_connected(peer_id: int) -> void:
    if not forest_active or not _is_authoritative():
        return
    _receive_weather_state.rpc_id(peer_id, current_weather, weather_timer)
    call_deferred("_send_wildlife_state_to_peer", peer_id)

func _send_wildlife_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if not _is_authoritative():
        return
    var state: Dictionary = {}
    for id_value: Variant in animals.keys():
        var animal_id: String = str(id_value)
        var animal: Node3D = animals.get(animal_id, null) as Node3D
        if animal == null:
            continue
        state[animal_id] = {
            "position": animal.global_position,
            "yaw": animal.rotation.y,
            "alive": bool(animal.get("alive")),
            "health": float(animal.get("current_health"))
        }
    _receive_wildlife_state.rpc_id(peer_id, state)

func _build_ui() -> void:
    ui_layer = CanvasLayer.new()
    ui_layer.name = "ForestSurvivalUI"
    ui_layer.layer = 36
    add_child(ui_layer)

    weather_tint = ColorRect.new()
    weather_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    weather_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui_layer.add_child(weather_tint)

    weather_label = Label.new()
    weather_label.anchor_left = 0.5
    weather_label.anchor_right = 0.5
    weather_label.offset_left = -220.0
    weather_label.offset_right = 220.0
    weather_label.offset_top = 74.0
    weather_label.offset_bottom = 104.0
    weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    weather_label.add_theme_font_size_override("font_size", 15)
    ui_layer.add_child(weather_label)

    hunt_button = Button.new()
    hunt_button.text = "HUNT"
    hunt_button.focus_mode = Control.FOCUS_NONE
    hunt_button.custom_minimum_size = Vector2(92.0, 48.0)
    hunt_button.pressed.connect(_try_hunt)
    ui_layer.add_child(hunt_button)
    _set_ui_visible(false)

func _update_ui(player: CharacterBody3D) -> void:
    if not forest_active:
        _set_ui_visible(false)
        return
    _set_ui_visible(true)

    var weather_name: String = "CERAH"
    match current_weather:
        "cloudy": weather_name = "BERAWAN"
        "rain": weather_name = "HUJAN"
        "storm": weather_name = "BADAI"
    if weather_label != null:
        weather_label.text = "CUACA %s  •  BASAH %d%%" % [weather_name, int(round(wetness))]

    if weather_tint != null:
        match current_weather:
            "storm": weather_tint.color = Color(0.06, 0.08, 0.12, 0.14)
            "rain": weather_tint.color = Color(0.08, 0.10, 0.13, 0.08)
            "cloudy": weather_tint.color = Color(0.08, 0.08, 0.09, 0.035)
            _: weather_tint.color = Color(0.0, 0.0, 0.0, 0.0)

    if hunt_button != null:
        var has_bow: bool = player != null and player.has_method("has_item") and bool(player.call("has_item", "hunting_bow"))
        hunt_button.visible = _mobile_active() and has_bow and not _ui_blocked()
        var size: Vector2 = get_viewport().get_visible_rect().size
        hunt_button.position = Vector2(size.x - 116.0, maxf(120.0, size.y * 0.30))

func _set_ui_visible(value: bool) -> void:
    if weather_label != null:
        weather_label.visible = value
    if weather_tint != null:
        weather_tint.visible = value
    if hunt_button != null and not value:
        hunt_button.visible = false

func _objective(player: CharacterBody3D, text: String) -> void:
    var label: Label = player.get_node_or_null("HUD/Objective") as Label
    if label != null:
        label.text = text

func _local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func _local_peer_id() -> int:
    return multiplayer.get_unique_id() if _network_online() else 1

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _ui_blocked() -> bool:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return true
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return true
    var inventory: Node = get_node_or_null("/root/SurvivalSystem/InventoryMenuRuntime")
    if inventory != null and inventory.has_method("is_open") and bool(inventory.call("is_open")):
        return true
    return false
