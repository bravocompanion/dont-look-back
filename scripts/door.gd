extends AnimatableBody3D

@export var open_angle_degrees: float = -95.0
@export var animation_time: float = 0.65

var is_open := false
var is_moving := false
var closed_rotation_y := 0.0

func _ready() -> void:
    closed_rotation_y = rotation.y

func get_interaction_text() -> String:
    return "Close door" if is_open else "Open door"

func interact() -> void:
    if is_moving:
        return

    is_moving = true
    is_open = not is_open
    var target_rotation := closed_rotation_y + deg_to_rad(open_angle_degrees if is_open else 0.0)
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "rotation:y", target_rotation, animation_time)
    await tween.finished
    is_moving = false
