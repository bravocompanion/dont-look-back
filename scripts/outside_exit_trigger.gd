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
    if transition == null:
        return

    # Ranger-first route: Forest -> Mine -> Labyrinth -> Research Facility.
    # Fall back to the old Forest exit only if the upgraded transition system
    # is not present, keeping older builds recoverable.
    var method_name: String = "request_research_transition" if transition.has_method("request_research_transition") else "request_forest_transition"
    if not transition.has_method(method_name):
        return

    triggered = true
    monitoring = false
    transition.call(method_name)
