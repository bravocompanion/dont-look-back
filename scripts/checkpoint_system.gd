extends Node

var checkpoint_active: bool = false
var checkpoint_position: Vector3 = Vector3.ZERO
var checkpoint_rotation_y: float = 0.0
var checkpoint_state: Dictionary = {}
var checkpoint_name: String = ""
var restore_pending: bool = false

func save_checkpoint(player: CharacterBody3D, world_position: Vector3, label: String) -> void:
    if player == null or not player.has_method("export_survival_state"):
        return

    checkpoint_active = true
    checkpoint_position = world_position
    checkpoint_rotation_y = player.rotation.y
    checkpoint_state = Dictionary(player.call("export_survival_state")).duplicate(true)
    checkpoint_name = label

func has_checkpoint() -> bool:
    return checkpoint_active

func get_checkpoint_name() -> String:
    return checkpoint_name

func request_restore() -> void:
    if checkpoint_active:
        restore_pending = true

func clear_checkpoint() -> void:
    checkpoint_active = false
    checkpoint_position = Vector3.ZERO
    checkpoint_rotation_y = 0.0
    checkpoint_state.clear()
    checkpoint_name = ""
    restore_pending = false

func _process(_delta: float) -> void:
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

    if player.has_method("import_survival_state"):
        player.call("import_survival_state", checkpoint_state.duplicate(true))

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Checkpoint restored: %s" % checkpoint_name
