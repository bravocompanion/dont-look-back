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
        objective.text = "Something is standing behind you."

    var light := get_node_or_null(flicker_light_path) as Light3D
    if light != null:
        light.visible = false
        await get_tree().create_timer(0.12).timeout
        light.visible = true
        await get_tree().create_timer(0.08).timeout
        light.visible = false
        await get_tree().create_timer(0.16).timeout
        light.visible = true

    var monster := get_node_or_null(monster_path)
    if monster != null and monster.has_method("appear"):
        monster.appear()
