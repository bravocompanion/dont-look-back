extends Node

var configured_scene_id: int = 0
var pickup_script: Script

func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id == configured_scene_id:
        return

    configured_scene_id = scene_id
    call_deferred("_configure_scene", scene)

func _configure_scene(scene: Node) -> void:
    if not is_instance_valid(scene):
        return

    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    var end_subtitle: Label = scene.get_node_or_null("Player/HUD/EndPanel/Subtitle") as Label
    if end_subtitle != null:
        end_subtitle.text = "DON'T LOOK BACK — v0.5: LIGHT & DARKNESS"

    var dark_corridor_light: OmniLight3D = scene.get_node_or_null("CeilingLight3") as OmniLight3D
    if dark_corridor_light != null:
        dark_corridor_light.light_energy = 0.08

    _spawn_pickup(scene, "SurvivalFood", "canned_food", "Canned Food", Vector3(-4.55, 0.02, -4.15))
    _spawn_pickup(scene, "SurvivalWater", "bottled_water", "Bottled Water", Vector3(-6.65, 0.02, -4.25))
    _spawn_pickup(scene, "SurvivalMedkit", "medkit", "Medkit", Vector3(-6.95, 0.02, -6.55))
    _spawn_pickup(scene, "FlashlightBatteryA", "flashlight_battery", "Flashlight Battery", Vector3(-4.25, 0.02, -6.45))
    _spawn_pickup(scene, "FlashlightBatteryB", "flashlight_battery", "Flashlight Battery", Vector3(1.15, 0.02, -8.85))

func _spawn_pickup(scene: Node, node_name: String, item_id: String, display_name: String, world_position: Vector3) -> void:
    if scene.has_node(NodePath(node_name)):
        return
    if pickup_script == null:
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../Player/HUD/Objective"))
    pickup.position = world_position
    scene.add_child(pickup)
