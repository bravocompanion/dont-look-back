extends AnimatableBody3D

@export var required_item_id: String = "exit_key"
@export var open_angle_degrees: float = -95.0
@export var animation_time: float = 0.65
@export var objective_label_path: NodePath

var unlocked: bool = false
var is_open: bool = false
var is_moving: bool = false
var closed_rotation_y: float = 0.0

func _ready() -> void:
    closed_rotation_y = rotation.y

func get_interaction_text() -> String:
    if is_open:
        return "Close exit door"
    if unlocked:
        return "Open exit door"
    return "Unlock exit door"

func interact() -> void:
    if is_moving:
        return

    var objective: Label = get_node_or_null(objective_label_path) as Label

    if not unlocked:
        var player: Node = get_tree().get_first_node_in_group("player")
        if player == null or not player.has_method("has_item"):
            return

        var has_key: bool = bool(player.call("has_item", required_item_id))
        if not has_key:
            if objective != null:
                objective.text = "The exit is locked. Search Apartment 03 for a key."
            return

        if player.has_method("remove_item"):
            player.call("remove_item", required_item_id)
        unlocked = true
        if objective != null:
            objective.text = "The exit is unlocked. Get out."

    is_moving = true
    is_open = not is_open
    var angle: float = open_angle_degrees if is_open else 0.0
    var target_rotation: float = closed_rotation_y + deg_to_rad(angle)
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "rotation:y", target_rotation, animation_time)
    await tween.finished
    is_moving = false
