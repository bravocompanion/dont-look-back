extends Area3D

@export var monster_path: NodePath
@export var objective_label_path: NodePath

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return

    triggered = true

    # v0.24.2: entering this old story/safe trigger no longer deletes the
    # Tenant. The learned counter is now a continuous 3-second flashlight beam.
    var objective: Label = get_node_or_null(objective_label_path) as Label
    if objective != null:
        objective.text = "Search Apartment 03 for the exit key. Keep the Tenant in your light if it appears."
