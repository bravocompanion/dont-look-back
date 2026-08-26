extends "res://scripts/movement_system_v43.gd"

# v0.74.2: locomotion owns move_and_slide(), so forest containment is enforced
# immediately after the movement tick as well as by the map safety fallback.

func _physics_process(delta: float) -> void:
    super._physics_process(delta)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not is_instance_valid(player):
        return

    var forest_safety: Node = get_node_or_null("/root/ForestWorldExpansion")
    if forest_safety != null and forest_safety.has_method("enforce_player_safety_v742"):
        forest_safety.call("enforce_player_safety_v742", player)

func get_forest_movement_safety_contract_v742() -> Dictionary:
    return {
        "post_move_safety": true,
        "runs_after_move_and_slide": true,
        "forest_only": true,
        "mobile_and_desktop_shared_path": true
    }
