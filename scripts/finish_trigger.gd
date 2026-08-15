extends Area3D

@export var end_panel_path: NodePath
var finished := false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if finished or not body.is_in_group("player"):
        return
    finished = true

    var monster := get_node_or_null("../Monster")
    if monster != null and monster.has_method("stop_stalking"):
        monster.stop_stalking()

    if body is CharacterBody3D:
        body.velocity = Vector3.ZERO
        body.set_physics_process(false)
        body.set_process_unhandled_input(false)

    var panel := get_node_or_null(end_panel_path) as Control
    if panel != null:
        panel.visible = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
