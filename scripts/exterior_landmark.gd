extends Area3D

@export var landmark_name: String = "Unknown Place"
@export var objective_text: String = "Search the area for supplies."

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return
    triggered = true

    var player: CharacterBody3D = body as CharacterBody3D
    if player == null:
        return

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "%s — %s" % [landmark_name, objective_text]
