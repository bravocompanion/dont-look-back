extends Node

@export var max_condition: float = 100.0
@export var bleed_damage_interval: float = 4.0
@export var infection_damage_interval: float = 5.0
@export var dirty_water_infection: float = 18.0
@export var bandage_bleed_reduction: float = 72.0
@export var medkit_infection_reduction: float = 38.0

var bleeding: float = 0.0
var infection: float = 0.0
var bleed_damage_timer: float = 4.0
var infection_damage_timer: float = 5.0
var configured_scene_id: int = 0
var starter_spawn_scene_id: int = 0
var outside_spawn_scene_id: int = 0
var status_label: Label
var ui_timer: float = 0.0
var pickup_script: Script
var boiler_script: Script

func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    boiler_script = load("res://scripts/water_boiler.gd") as Script
    bleed_damage_timer = bleed_damage_interval
    infection_damage_timer = infection_damage_interval

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        status_label = null
        call_deferred("_configure_scene", scene)

    _ensure_processing_world(scene)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    _ensure_status_label(player)

    if _is_local_player_downed():
        _update_status_label(player)
        return

    if bleeding > 0.0:
        bleeding = maxf(0.0, bleeding - 0.08 * delta)
        infection = minf(max_condition, infection + (0.025 + bleeding * 0.0012) * delta)

        bleed_damage_timer -= delta
        if bleeding >= 18.0 and bleed_damage_timer <= 0.0:
            bleed_damage_timer = bleed_damage_interval
            var bleed_damage: float = 1.0 if bleeding < 60.0 else 2.0
            if player.has_method("apply_damage"):
                player.call("apply_damage", bleed_damage, "bleeding")
    else:
        bleed_damage_timer = bleed_damage_interval
        if infection < 12.0:
            infection = maxf(0.0, infection - 0.025 * delta)

    if infection >= 60.0:
        var current_stamina: float = float(player.get("stamina"))
        player.set("stamina", maxf(0.0, current_stamina - 0.32 * delta))

    infection_damage_timer -= delta
    if infection >= 90.0 and infection_damage_timer <= 0.0:
        infection_damage_timer = infection_damage_interval
        if player.has_method("apply_damage"):
            player.call("apply_damage", 2.0, "infection")
    elif infection < 90.0:
        infection_damage_timer = maxf(infection_damage_timer, 1.0)

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.25
        _update_status_label(player)

func report_damage(player: CharacterBody3D, amount: float, source_name: String) -> void:
    if player == null or amount < 10.0:
        return
    if source_name in ["bleeding", "infection", "starvation", "dehydration", "exposure"]:
        return

    var added_bleeding: float = clampf(amount * 1.35, 14.0, 42.0)
    bleeding = minf(max_condition, bleeding + added_bleeding)

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "You're bleeding. Use a Bandage or Medkit before the wound gets infected."

func consume_water(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    if player.has_method("remove_item") and bool(player.call("remove_item", "bottled_water")):
        var clean_thirst: float = minf(float(player.get("max_thirst")), float(player.get("thirst")) + 55.0)
        player.set("thirst", clean_thirst)
        infection = maxf(0.0, infection - 1.5)
        _set_objective(player, "You drink clean water.")
        return true

    if player.has_method("remove_item") and bool(player.call("remove_item", "dirty_water")):
        var dirty_thirst: float = minf(float(player.get("max_thirst")), float(player.get("thirst")) + 38.0)
        player.set("thirst", dirty_thirst)
        infection = minf(max_condition, infection + dirty_water_infection)
        _set_objective(player, "You drink untreated water. It helps your thirst, but infection risk rises.")
        return true

    _set_objective(player, "You have no water.")
    return false

func use_medical_aid(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    if bleeding >= 5.0 and player.has_method("remove_item") and bool(player.call("remove_item", "bandage")):
        bleeding = maxf(0.0, bleeding - bandage_bleed_reduction)
        infection = maxf(0.0, infection - 6.0)
        _set_objective(player, "You bind the wound with a Bandage.")
        return true

    var health: float = float(player.get("health"))
    var max_health: float = float(player.get("max_health"))
    var needs_medkit: bool = health < max_health or bleeding > 0.0 or infection > 0.0
    if needs_medkit and player.has_method("remove_item") and bool(player.call("remove_item", "medkit")):
        if player.has_method("heal"):
            player.call("heal", 45.0)
        bleeding = 0.0
        infection = maxf(0.0, infection - medkit_infection_reduction)
        _set_objective(player, "You clean and dress your wounds with the Medkit.")
        return true

    if bleeding >= 5.0:
        _set_objective(player, "You need a Bandage or Medkit to stop the bleeding.")
    elif infection > 0.0:
        _set_objective(player, "You need a Medkit to treat the infection.")
    elif health >= max_health:
        _set_objective(player, "You do not need medical aid right now.")
    else:
        _set_objective(player, "You have no medical supplies.")
    return false

func boil_water(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null or not shelter.has_method("get_campfire_percent"):
        _set_objective(player, "The boiling pot needs the shelter campfire.")
        return false

    var fire_percent: int = int(shelter.call("get_campfire_percent"))
    if fire_percent <= 0:
        _set_objective(player, "Light the campfire before boiling water.")
        return false

    if not player.has_method("remove_item") or not bool(player.call("remove_item", "dirty_water")):
        _set_objective(player, "You have no Dirty Water to boil.")
        return false

    if not player.has_method("add_item") or not bool(player.call("add_item", "bottled_water", "Clean Water")):
        if player.has_method("add_item"):
            player.call("add_item", "dirty_water", "Dirty Water")
        _set_objective(player, "Inventory full. The Dirty Water was not processed.")
        return false

    _set_objective(player, "You boil the Dirty Water into safe Clean Water.")
    return true

func get_bleeding() -> float:
    return bleeding

func get_infection() -> float:
    return infection

func _configure_scene(scene: Node) -> void:
    if not is_instance_valid(scene):
        return
    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return
    _ensure_processing_world(scene)

func _ensure_processing_world(scene: Node) -> void:
    var scene_id: int = int(scene.get_instance_id())

    if starter_spawn_scene_id != scene_id:
        starter_spawn_scene_id = scene_id
        _spawn_pickup(scene, "DepthClothStarterA", "cloth", "Cloth", Vector3(-5.35, 0.02, -4.95), NodePath("../Player/HUD/Objective"))
        _spawn_pickup(scene, "DepthClothStarterB", "cloth", "Cloth", Vector3(-6.75, 0.02, -6.25), NodePath("../Player/HUD/Objective"))

    var outside: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside == null or outside_spawn_scene_id == scene_id:
        return

    outside_spawn_scene_id = scene_id

    if boiler_script != null and not outside.has_node(NodePath("WaterBoiler")):
        var boiler: StaticBody3D = StaticBody3D.new()
        boiler.name = "WaterBoiler"
        boiler.set_script(boiler_script)
        boiler.position = Vector3(15.35, 0.0, -74.5)
        outside.add_child(boiler)

    _spawn_pickup(outside, "DepthClothHouse", "cloth", "Cloth", Vector3(-24.2, 0.02, -149.0), NodePath("../../Player/HUD/Objective"))
    _spawn_pickup(outside, "DepthClothGas", "cloth", "Cloth", Vector3(24.5, 0.02, -165.4), NodePath("../../Player/HUD/Objective"))
    _spawn_pickup(outside, "DepthClothWarehouseA", "cloth", "Cloth", Vector3(-6.8, 0.02, -186.0), NodePath("../../Player/HUD/Objective"))
    _spawn_pickup(outside, "DepthClothWarehouseB", "cloth", "Cloth", Vector3(-10.2, 0.02, -190.5), NodePath("../../Player/HUD/Objective"))

func _spawn_pickup(parent: Node, node_name: String, item_id: String, display_name: String, position: Vector3, objective_path: NodePath) -> void:
    if pickup_script == null or parent.has_node(NodePath(node_name)):
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", objective_path)
    pickup.position = position
    parent.add_child(pickup)

func _ensure_status_label(player: CharacterBody3D) -> void:
    if status_label != null and is_instance_valid(status_label):
        return

    var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return

    status_label = Label.new()
    status_label.name = "ConditionStatus"
    status_label.anchor_left = 1.0
    status_label.anchor_right = 1.0
    status_label.anchor_top = 0.0
    status_label.anchor_bottom = 0.0
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(status_label)
    _update_status_label(player)

func _update_status_label(player: CharacterBody3D) -> void:
    if status_label == null:
        return

    var viewport_width: float = player.get_viewport().get_visible_rect().size.x
    if viewport_width < 800.0:
        status_label.offset_left = -205.0
        status_label.offset_right = -12.0
        status_label.offset_top = 205.0
        status_label.offset_bottom = 242.0
        status_label.add_theme_font_size_override("font_size", 12)
        status_label.text = "BLEED %d%%  INF %d%%" % [int(round(bleeding)), int(round(infection))]
    else:
        status_label.offset_left = -270.0
        status_label.offset_right = -28.0
        status_label.offset_top = 280.0
        status_label.offset_bottom = 318.0
        status_label.add_theme_font_size_override("font_size", 15)
        status_label.text = "BLEEDING %3d%%  |  INFECTION %3d%%" % [int(round(bleeding)), int(round(infection))]

func _is_local_player_downed() -> bool:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return false
    return bool(coop.get("local_downed"))

func _set_objective(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text
