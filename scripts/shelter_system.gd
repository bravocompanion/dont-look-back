extends Node

@export var generator_max_fuel_seconds: float = 720.0
@export var generator_fuel_per_can: float = 360.0
@export var campfire_max_seconds: float = 480.0
@export var campfire_bundle_seconds: float = 240.0
@export var campfire_wood_seconds: float = 90.0

var configured_scene_id: int = 0
var attached_scene_id: int = 0
var outside_root: Node3D
var shelter_generator: StaticBody3D
var campfire_light: OmniLight3D
var status_label: Label

var workbench_script: Script
var chest_script: Script
var campfire_script: Script
var bed_script: Script
var pickup_script: Script

var generator_running: bool = false
var generator_fuel_seconds: float = 0.0
var campfire_burn_seconds: float = 0.0
var storage_names: Dictionary = {}
var storage_counts: Dictionary = {}
var ui_timer: float = 0.0

const CAMPFIRE_POSITION: Vector3 = Vector3(14.0, 0.0, -74.5)
const SHELTER_CHECKPOINT: Vector3 = Vector3(14.0, 0.92, -82.2)
const STORAGE_PRIORITY: Array[String] = [
    "generator_fuel", "flashlight_battery", "medkit", "bottled_water",
    "canned_food", "firewood_bundle", "wood", "scrap"
]

func _ready() -> void:
    workbench_script = load("res://scripts/shelter_workbench.gd") as Script
    chest_script = load("res://scripts/shelter_chest.gd") as Script
    campfire_script = load("res://scripts/shelter_campfire.gd") as Script
    bed_script = load("res://scripts/shelter_bed.gd") as Script
    pickup_script = load("res://scripts/survival_pickup.gd") as Script

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        attached_scene_id = 0
        outside_root = null
        shelter_generator = null
        campfire_light = null
        status_label = null

    if attached_scene_id != scene_id:
        var candidate: Node = scene.get_node_or_null("OutsideWorld")
        if candidate != null:
            outside_root = candidate as Node3D
            if outside_root != null:
                _attach_shelter_objects()
                attached_scene_id = scene_id

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null or not outside.has_method("is_outside_active"):
        return

    var outside_active: bool = bool(outside.call("is_outside_active"))
    if not outside_active:
        if status_label != null:
            status_label.visible = false
        return

    if status_label != null:
        status_label.visible = true

    if generator_running:
        generator_fuel_seconds = maxf(0.0, generator_fuel_seconds - delta)
        if generator_fuel_seconds <= 0.0:
            generator_running = false
            _sync_generator_state()
            _announce("The shelter generator ran out of fuel.")

    if campfire_burn_seconds > 0.0:
        campfire_burn_seconds = maxf(0.0, campfire_burn_seconds - delta)
        _apply_campfire_state()

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        _apply_campfire_warmth(player, outside, delta)
        _ensure_status_label(player)

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.25
        _update_status_label(player)

func activate_generator(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if generator_running:
        return refuel_generator(player)
    if not _consume_item(player, "generator_fuel"):
        _set_objective(player, "The generator is dry. Find a Fuel Can outside.")
        return false

    generator_fuel_seconds = minf(generator_max_fuel_seconds, generator_fuel_seconds + generator_fuel_per_can)
    generator_running = true
    _sync_generator_state()
    _save_shelter_checkpoint(player)
    _set_objective(player, "SHELTER ONLINE — Generator started. Checkpoint saved.")
    return true

func refuel_generator(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if generator_fuel_seconds >= generator_max_fuel_seconds - 1.0:
        _set_objective(player, "Generator fuel tank is full.")
        return false
    if not _consume_item(player, "generator_fuel"):
        _set_objective(player, "You have no Fuel Can.")
        return false

    generator_fuel_seconds = minf(generator_max_fuel_seconds, generator_fuel_seconds + generator_fuel_per_can)
    generator_running = true
    _sync_generator_state()
    _set_objective(player, "Fuel added to the shelter generator.")
    return true

func get_generator_percent() -> int:
    if generator_max_fuel_seconds <= 0.0:
        return 0
    return int(round(clampf(generator_fuel_seconds / generator_max_fuel_seconds, 0.0, 1.0) * 100.0))

func is_generator_running() -> bool:
    return generator_running

func fuel_campfire(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var added_seconds: float = 0.0
    if _consume_item(player, "firewood_bundle"):
        added_seconds = campfire_bundle_seconds
        _set_objective(player, "You feed the campfire with a Firewood Bundle.")
    elif _consume_item(player, "wood"):
        added_seconds = campfire_wood_seconds
        _set_objective(player, "You add loose wood to the campfire.")
    else:
        _set_objective(player, "The campfire needs Wood or a crafted Firewood Bundle.")
        return false

    campfire_burn_seconds = minf(campfire_max_seconds, campfire_burn_seconds + added_seconds)
    _apply_campfire_state()
    return true

func get_campfire_percent() -> int:
    if campfire_max_seconds <= 0.0:
        return 0
    return int(round(clampf(campfire_burn_seconds / campfire_max_seconds, 0.0, 1.0) * 100.0))

func store_one_supply(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var names: Dictionary = Dictionary(player.get("inventory_names"))
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))

    for item_id: String in STORAGE_PRIORITY:
        var count: int = int(counts.get(item_id, 0))
        if count <= 0:
            continue
        if not _consume_item(player, item_id):
            continue

        var display_name: String = str(names.get(item_id, _default_display_name(item_id)))
        storage_names[item_id] = display_name
        storage_counts[item_id] = int(storage_counts.get(item_id, 0)) + 1
        _set_objective(player, "Stored %s. Chest now holds %d items." % [display_name, _storage_total()])
        return true

    _set_objective(player, "No survival supplies available to store.")
    return false

func take_one_supply(player: CharacterBody3D) -> bool:
    if player == null or not player.has_method("add_item"):
        return false

    for item_id: String in STORAGE_PRIORITY:
        var count: int = int(storage_counts.get(item_id, 0))
        if count <= 0:
            continue

        var display_name: String = str(storage_names.get(item_id, _default_display_name(item_id)))
        var accepted: bool = bool(player.call("add_item", item_id, display_name))
        if not accepted:
            _set_objective(player, "Inventory full. Cannot take %s." % display_name)
            return false

        count -= 1
        if count <= 0:
            storage_counts.erase(item_id)
            storage_names.erase(item_id)
        else:
            storage_counts[item_id] = count

        _set_objective(player, "Took %s from storage. Chest holds %d items." % [display_name, _storage_total()])
        return true

    _set_objective(player, "The storage chest is empty.")
    return false

func sleep_until_morning(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return false

    var current_minutes: float = float(outside.get("game_minutes"))
    if current_minutes >= 300.0 and current_minutes < 1080.0:
        _set_objective(player, "It is too early to sleep. Prepare the shelter before night.")
        return false

    var sleep_hours: float = 0.0
    var crosses_midnight: bool = false
    if current_minutes >= 1080.0:
        sleep_hours = (1440.0 - current_minutes + 420.0) / 60.0
        crosses_midnight = true
    else:
        sleep_hours = (420.0 - current_minutes) / 60.0

    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds")))
    var protection_seconds_needed: float = sleep_hours * full_day_seconds / 24.0
    var generator_cover: float = generator_fuel_seconds if generator_running else 0.0
    var fire_cover: float = campfire_burn_seconds

    if maxf(generator_cover, fire_cover) + 0.01 < protection_seconds_needed:
        _set_objective(player, "Not enough light fuel to survive the night. Refuel the generator or campfire.")
        return false

    if generator_running:
        generator_fuel_seconds = maxf(0.0, generator_fuel_seconds - protection_seconds_needed)
        if generator_fuel_seconds <= 0.0:
            generator_running = false
            _sync_generator_state()

    if campfire_burn_seconds > 0.0:
        campfire_burn_seconds = maxf(0.0, campfire_burn_seconds - protection_seconds_needed)
        _apply_campfire_state()

    outside.set("game_minutes", 420.0)
    if crosses_midnight:
        outside.set("day_index", int(outside.get("day_index")) + 1)
    outside.set("cold_exposure", 0.0)

    var hunger: float = maxf(0.0, float(player.get("hunger")) - sleep_hours * 1.3)
    var thirst: float = maxf(0.0, float(player.get("thirst")) - sleep_hours * 2.0)
    player.set("hunger", hunger)
    player.set("thirst", thirst)
    player.set("stamina", float(player.get("max_stamina")))
    player.set("darkness_exposure", 0.0)

    if hunger > 20.0 and thirst > 20.0 and player.has_method("heal"):
        player.call("heal", 10.0)

    var dark_creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if dark_creature != null:
        dark_creature.queue_free()

    _save_shelter_checkpoint(player)
    _set_objective(player, "You survived the night. Morning light returns. Checkpoint saved.")
    return true

func _attach_shelter_objects() -> void:
    if outside_root == null:
        return

    shelter_generator = outside_root.get_node_or_null("ShelterGenerator") as StaticBody3D
    _spawn_scripted_body("ShelterWorkbench", workbench_script, Vector3(11.6, 0.0, -80.4))
    _spawn_scripted_body("ShelterChest", chest_script, Vector3(16.4, 0.0, -80.4))
    _spawn_scripted_body("ShelterCampfire", campfire_script, CAMPFIRE_POSITION)
    _spawn_scripted_body("ShelterBed", bed_script, Vector3(11.7, 0.0, -84.0))

    campfire_light = outside_root.get_node_or_null("CampfireLight") as OmniLight3D
    if campfire_light == null:
        campfire_light = OmniLight3D.new()
        campfire_light.name = "CampfireLight"
        campfire_light.position = CAMPFIRE_POSITION + Vector3(0.0, 1.0, 0.0)
        campfire_light.light_color = Color(1.0, 0.48, 0.18, 1.0)
        campfire_light.light_energy = 0.0
        campfire_light.omni_range = 7.0
        campfire_light.shadow_enabled = true
        outside_root.add_child(campfire_light)

    _spawn_resource_pickups()
    _sync_generator_state()
    _apply_campfire_state()

func _spawn_scripted_body(node_name: String, script_resource: Script, position: Vector3) -> void:
    if outside_root == null or script_resource == null:
        return
    if outside_root.has_node(NodePath(node_name)):
        return

    var body: StaticBody3D = StaticBody3D.new()
    body.name = StringName(node_name)
    body.set_script(script_resource)
    body.position = position
    outside_root.add_child(body)

func _spawn_resource_pickups() -> void:
    _spawn_pickup("WoodA", "wood", "Wood", Vector3(8.5, 0.02, -68.0))
    _spawn_pickup("WoodB", "wood", "Wood", Vector3(-16.0, 0.02, -87.0))
    _spawn_pickup("WoodC", "wood", "Wood", Vector3(22.0, 0.02, -97.0))
    _spawn_pickup("WoodD", "wood", "Wood", Vector3(-26.0, 0.02, -119.0))
    _spawn_pickup("ScrapA", "scrap", "Scrap", Vector3(-6.5, 0.02, -79.0))
    _spawn_pickup("ScrapB", "scrap", "Scrap", Vector3(18.5, 0.02, -108.0))
    _spawn_pickup("ScrapC", "scrap", "Scrap", Vector3(-28.0, 0.02, -96.0))
    _spawn_pickup("OutsideFuelReserve", "generator_fuel", "Fuel Can", Vector3(29.0, 0.02, -122.0))

func _spawn_pickup(node_name: String, item_id: String, display_name: String, position: Vector3) -> void:
    if outside_root == null or pickup_script == null:
        return
    if outside_root.has_node(NodePath(node_name)):
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../Player/HUD/Objective"))
    pickup.position = position
    outside_root.add_child(pickup)

func _sync_generator_state() -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        outside.set("shelter_powered", generator_running)
        if outside.has_method("_apply_shelter_power"):
            outside.call("_apply_shelter_power")

    if shelter_generator != null and is_instance_valid(shelter_generator) and shelter_generator.has_method("set_powered_from_restore"):
        shelter_generator.call("set_powered_from_restore", generator_running)

func _apply_campfire_state() -> void:
    if campfire_light == null or not is_instance_valid(campfire_light):
        return
    if campfire_burn_seconds <= 0.0:
        campfire_light.light_energy = 0.0
        return

    var ratio: float = clampf(campfire_burn_seconds / campfire_max_seconds, 0.0, 1.0)
    campfire_light.light_energy = lerpf(0.85, 1.65, ratio)

func _apply_campfire_warmth(player: CharacterBody3D, outside: Node, delta: float) -> void:
    if campfire_burn_seconds <= 0.0:
        return
    if player.global_position.distance_to(CAMPFIRE_POSITION) > 6.5:
        return

    var cold: float = float(outside.get("cold_exposure"))
    outside.set("cold_exposure", maxf(0.0, cold - 5.0 * delta))

func _ensure_status_label(player: CharacterBody3D) -> void:
    if status_label != null and is_instance_valid(status_label):
        return

    var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return

    status_label = Label.new()
    status_label.name = "ShelterStatus"
    status_label.anchor_left = 0.5
    status_label.anchor_right = 0.5
    status_label.anchor_top = 0.0
    status_label.anchor_bottom = 0.0
    status_label.offset_left = -240.0
    status_label.offset_right = 240.0
    status_label.offset_top = 48.0
    status_label.offset_bottom = 76.0
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 15)
    hud.add_child(status_label)

func _update_status_label(player: CharacterBody3D) -> void:
    if status_label == null:
        return

    var width: float = 1280.0
    if player != null:
        width = player.get_viewport().get_visible_rect().size.x

    var generator_percent: int = get_generator_percent()
    var fire_percent: int = get_campfire_percent()
    var stored: int = _storage_total()

    if width < 800.0:
        status_label.offset_left = -150.0
        status_label.offset_right = 150.0
        status_label.add_theme_font_size_override("font_size", 12)
        status_label.text = "GEN %d%%  FIRE %d%%  BOX %d" % [generator_percent, fire_percent, stored]
    else:
        status_label.offset_left = -245.0
        status_label.offset_right = 245.0
        status_label.add_theme_font_size_override("font_size", 15)
        status_label.text = "SHELTER  |  GENERATOR %d%%  |  CAMPFIRE %d%%  |  STORAGE %d" % [generator_percent, fire_percent, stored]

func _consume_item(player: CharacterBody3D, item_id: String) -> bool:
    if not player.has_method("remove_item"):
        return false
    return bool(player.call("remove_item", item_id))

func _save_shelter_checkpoint(player: CharacterBody3D) -> void:
    var checkpoint_system: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint_system != null and checkpoint_system.has_method("save_checkpoint"):
        checkpoint_system.call("save_checkpoint", player, SHELTER_CHECKPOINT, "Forest shelter")

func _storage_total() -> int:
    var total: int = 0
    for value: Variant in storage_counts.values():
        total += int(value)
    return total

func _set_objective(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _announce(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        _set_objective(player, text)

func _default_display_name(item_id: String) -> String:
    match item_id:
        "generator_fuel": return "Fuel Can"
        "flashlight_battery": return "Flashlight Battery"
        "medkit": return "Medkit"
        "bottled_water": return "Bottled Water"
        "canned_food": return "Canned Food"
        "firewood_bundle": return "Firewood Bundle"
        "wood": return "Wood"
        "scrap": return "Scrap"
        _: return item_id.capitalize()
