extends StaticBody3D

@export var item_id: String = "exit_key"
@export var display_name: String = "Apartment Exit Key"
@export var objective_label_path: NodePath

var collected: bool = false

func get_interaction_text() -> String:
    return "Pick up " + display_name

func interact() -> void:
    if collected:
        return

    var player: Node = get_tree().get_first_node_in_group("player")
    if player == null or not player.has_method("add_item"):
        return

    var accepted: bool = bool(player.call("add_item", item_id, display_name))
    var objective: Label = get_node_or_null(objective_label_path) as Label

    if not accepted:
        if objective != null:
            objective.text = "Inventory full."
        return

    collected = true
    if objective != null:
        objective.text = "You found the exit key. Return to the hallway."

    queue_free()
