extends Area3D

# Non-blocking interaction target for a dead wildlife body. The living
# CharacterBody collision can stay disabled while the player's InteractionRay
# still has something safe to hit for harvesting.

func get_interaction_text() -> String:
    var animal: Node = get_parent()
    if animal != null and animal.has_method("get_corpse_interaction_text_v52"):
        return str(animal.call("get_corpse_interaction_text_v52"))
    return "Harvest carcass"

func interact() -> void:
    var animal: Node = get_parent()
    if animal != null and animal.has_method("request_corpse_collect_v52"):
        animal.call("request_corpse_collect_v52")
