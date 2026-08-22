extends StaticBody3D

# Non-blocking-for-player interaction target on collision layer 2. The player
# movement body uses the normal world mask, while Forest InteractionRay includes
# this extra layer so a dead carcass can be harvested without becoming an obstacle.

func get_interaction_text() -> String:
    var animal: Node = get_parent()
    if animal != null and animal.has_method("get_corpse_interaction_text_v52"):
        return str(animal.call("get_corpse_interaction_text_v52"))
    return "Harvest carcass"

func interact() -> void:
    var animal: Node = get_parent()
    if animal != null and animal.has_method("request_corpse_collect_v52"):
        animal.call("request_corpse_collect_v52")
