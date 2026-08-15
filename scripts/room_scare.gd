extends Area3D

@export var figure_path: NodePath
@export var room_light_path: NodePath
@export var objective_label_path: NodePath

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return

    triggered = true

    var figure: Node3D = get_node_or_null(figure_path) as Node3D
    var light: Light3D = get_node_or_null(room_light_path) as Light3D
    var objective: Label = get_node_or_null(objective_label_path) as Label
    var delays: Array[float] = [0.07, 0.05, 0.11, 0.06]

    if light != null:
        for delay: float in delays:
            light.visible = not light.visible
            await get_tree().create_timer(delay).timeout
        light.visible = true

    if figure != null:
        figure.visible = true

    if objective != null:
        objective.text = "Something was already inside. Find the key."

    await get_tree().create_timer(0.75).timeout

    if light != null:
        light.visible = false
        await get_tree().create_timer(0.10).timeout
        light.visible = true

    if figure != null:
        figure.visible = false
