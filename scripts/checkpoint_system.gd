extends Node

var checkpoint_active: bool = false
var checkpoint_position: Vector3 = Vector3.ZERO
var checkpoint_rotation_y: float = 0.0
var checkpoint_state: Dictionary = {}
var checkpoint_name: String = ""
var last_scene_id: int = 0
var restore_pending: bool = false

func _ready() -> void:
    var scene: Node = get_tree().current_scene
    if scene != null:
        last_scene_id = int(scene.get_instance_id())

func save_checkpoint(player: CharacterBody3D, world_position: Vector3, label: String) -> void:
    if player == null:
        return

    checkpoint_active = true
    checkpoint_position = world_position
    checkpoint_rotation_y = player.rotation.y
    checkpoint_name = label
    checkpoint_state = {
        "health": float(player.get("health")),
        "hunger": float(player.get("hunger")),
        "thirst": float(player.get("thirst")),
        "stamina": float(player.get("stamina")),
        "flashlight_battery": float(player.get("flashlight_battery")),
        "darkness_exposure": float(player.get("darkness_exposure")),
        "inventory_names": Dictionary(player.get("inventory_names")).duplicate(true),
        "inventory_counts": Dictionary(player.get("inventory_counts")).duplicate(true),
        "flashlight_on": _is_flashlight_on(player)
    }

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        checkpoint_state["bleeding"] = float(depth.get("bleeding"))
        checkpoint_state["infection"] = float(depth.get("infection"))

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        checkpoint_state["cold_exposure"] = float(outside.get("cold_exposure"))

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", label)

func has_checkpoint() -> bool:
    return checkpoint_active

func get_checkpoint_name() -> String:
    return checkpoint_name

func clear_checkpoint() -> void:
    checkpoint_active = false
    checkpoint_position = Vector3.ZERO
    checkpoint_rotation_y = 0.0
    checkpoint_state.clear()
    checkpoint_name = ""
    restore_pending = false

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != last_scene_id:
        last_scene_id = scene_id
        if checkpoint_active:
            restore_pending = true

    if not restore_pending or not checkpoint_active:
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    restore_pending = false
    call_deferred("_restore_player", player)

func _restore_player(player: CharacterBody3D) -> void:
    if not is_instance_valid(player):
        return

    await get_tree().process_frame
    await get_tree().process_frame
    if not is_instance_valid(player):
        return

    player.global_position = checkpoint_position
    player.rotation.y = checkpoint_rotation_y
    player.velocity = Vector3.ZERO

    player.set("health", float(checkpoint_state.get("health", 100.0)))
    player.set("hunger", float(checkpoint_state.get("hunger", 100.0)))
    player.set("thirst", float(checkpoint_state.get("thirst", 100.0)))
    player.set("stamina", float(checkpoint_state.get("stamina", 100.0)))
    player.set("flashlight_battery", float(checkpoint_state.get("flashlight_battery", 100.0)))
    player.set("darkness_exposure", minf(30.0, float(checkpoint_state.get("darkness_exposure", 0.0))))
    player.set("inventory_names", Dictionary(checkpoint_state.get("inventory_names", {})).duplicate(true))
    player.set("inventory_counts", Dictionary(checkpoint_state.get("inventory_counts", {})).duplicate(true))
    player.set("is_dead", false)

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth != null:
        depth.set("bleeding", clampf(float(checkpoint_state.get("bleeding", 0.0)), 0.0, 100.0))
        depth.set("infection", clampf(float(checkpoint_state.get("infection", 0.0)), 0.0, 100.0))
        depth.set("last_health", float(player.get("health")))
        depth.set("tracked_player_id", int(player.get_instance_id()))

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null and checkpoint_state.has("cold_exposure"):
        outside.set("cold_exposure", clampf(float(checkpoint_state["cold_exposure"]), 0.0, 100.0))

    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight != null:
        flashlight.visible = bool(checkpoint_state.get("flashlight_on", true)) and float(player.get("flashlight_battery")) > 0.0

    var death_panel: Control = player.get_node_or_null("HUD/CaughtPanel") as Control
    if death_panel != null:
        death_panel.visible = false

    if player.has_method("_update_inventory_hud"):
        player.call("_update_inventory_hud")
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Checkpoint restored: %s" % checkpoint_name

func _is_flashlight_on(player: CharacterBody3D) -> bool:
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    return flashlight != null and flashlight.visible
