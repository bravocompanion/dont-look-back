extends Node3D

@export var player_path: NodePath
@export var objective_label_path: NodePath

var armed := false
var can_vanish := false

func _ready() -> void:
    visible = false

func appear() -> void:
    visible = true
    armed = true
    can_vanish = false
    await get_tree().create_timer(0.35).timeout
    can_vanish = true

func _process(_delta: float) -> void:
    if not visible or not armed or not can_vanish:
        return

    var player := get_node_or_null(player_path)
    if player == null:
        return

    var camera := player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return

    var forward := -camera.global_transform.basis.z.normalized()
    var to_monster := (global_position - camera.global_position).normalized()

    if forward.dot(to_monster) > 0.965:
        visible = false
        armed = false
        var objective := get_node_or_null(objective_label_path) as Label
        if objective != null:
            objective.text = "It vanished. Reach the end of the hallway."
