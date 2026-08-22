extends StaticBody3D

@export var item_id: String = "exit_key"
@export var display_name: String = "Apartment Exit Key"
@export var objective_label_path: NodePath

var collected: bool = false

func _ready() -> void:
    call_deferred("_remove_if_already_claimed")

func get_interaction_text() -> String:
    return "Pick up " + display_name

func interact() -> void:
    if collected:
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not player.has_method("add_item"):
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    var accepted: bool = false
    if carry != null and carry.has_method("grant_item"):
        accepted = bool(carry.call("grant_item", player, item_id, display_name, 1))
    else:
        accepted = bool(player.call("add_item", item_id, display_name))

    var objective: Label = get_node_or_null(objective_label_path) as Label
    if not accepted:
        if objective != null:
            var status: String = str(carry.call("stack_status", player, item_id)) if carry != null and carry.has_method("stack_status") else "full"
            objective.text = "Cannot carry %s (%s). Make room first." % [display_name, status]
        return

    collected = true
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("register_claimed_pickup"):
        save_system.call("register_claimed_pickup", str(get_path()))

    if objective != null:
        objective.text = "%s added to inventory." % display_name

    queue_free()

func _remove_if_already_claimed() -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system == null or not save_system.has_method("is_pickup_claimed"):
        return
    if bool(save_system.call("is_pickup_claimed", str(get_path()))):
        queue_free()
