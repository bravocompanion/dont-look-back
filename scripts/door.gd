extends AnimatableBody3D

@export var open_angle_degrees: float = -95.0
@export var animation_time: float = 0.65
@export var safe_collision_restore_distance: float = 1.10

var is_open: bool = false
var is_moving: bool = false
var closed_rotation_y: float = 0.0
var pending_collision_restore: bool = false
var collision_shapes: Array[CollisionShape3D] = []

func _ready() -> void:
    closed_rotation_y = rotation.y
    _collect_collision_shapes(self)

func _process(_delta: float) -> void:
    if pending_collision_restore and not is_moving:
        _try_restore_collision()

func get_interaction_text() -> String:
    return "Close door" if is_open else "Open door"

func interact() -> void:
    if is_moving:
        return

    is_moving = true
    pending_collision_restore = false
    _set_collision_enabled(false)
    await get_tree().physics_frame

    is_open = not is_open
    var angle: float = open_angle_degrees if is_open else 0.0
    var target_rotation: float = closed_rotation_y + deg_to_rad(angle)
    var tween: Tween = create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(self, "rotation:y", target_rotation, animation_time)
    await tween.finished

    is_moving = false
    if is_open:
        _set_collision_enabled(true)
    else:
        pending_collision_restore = true
        _try_restore_collision()

func _collect_collision_shapes(node: Node) -> void:
    for child: Node in node.get_children():
        if child is CollisionShape3D:
            collision_shapes.append(child as CollisionShape3D)
        _collect_collision_shapes(child)

func _set_collision_enabled(enabled: bool) -> void:
    for shape: CollisionShape3D in collision_shapes:
        if shape != null and is_instance_valid(shape):
            shape.set_deferred("disabled", not enabled)

func _try_restore_collision() -> void:
    if not pending_collision_restore:
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        var horizontal_delta: Vector2 = Vector2(
            player.global_position.x - global_position.x,
            player.global_position.z - global_position.z
        )
        if horizontal_delta.length() < safe_collision_restore_distance:
            return

    pending_collision_restore = false
    _set_collision_enabled(true)
