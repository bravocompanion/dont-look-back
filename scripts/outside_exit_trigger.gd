extends Area3D

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return

    var player: CharacterBody3D = body as CharacterBody3D
    if player == null:
        return

    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition == null or not transition.has_method("request_forest_transition"):
        return

    triggered = true
    monitoring = false
    transition.call("request_forest_transition")
