extends Area3D

@export var monster_path: NodePath
@export var objective_label_path: NodePath
@export var flicker_light_path: NodePath

var triggered := false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return

    triggered = true
    var objective := get_node_or_null(objective_label_path) as Label
    if objective != null:
        objective.text = "The lights died behind you..."

    var light := get_node_or_null(flicker_light_path) as Light3D
    if light != null:
        for delay in [0.10, 0.06, 0.14, 0.05, 0.18]:
            light.visible = not light.visible
            await get_tree().create_timer(delay).timeout
        light.visible = true

    await get_tree().create_timer(0.25).timeout

    var monster := get_node_or_null(monster_path)
    if monster != null and monster.has_method("appear"):
        monster.appear()

    if objective != null:
        objective.text = "KEEP IT IN SIGHT. Open the door and reach the end."
