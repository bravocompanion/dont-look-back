extends "res://scripts/coop_horror_system_v58.gd"

# v0.59: every peer arms its locally captured checkpoint payload before the
# synchronized scene reload. CheckpointSystem then restores the shared host
# snapshot plus that peer's own checkpoint inventory/stats.

func _execute_team_wipe() -> void:
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint != null and checkpoint.has_method("prepare_team_wipe_restore_v59"):
        checkpoint.call("prepare_team_wipe_restore_v59")
    super._execute_team_wipe()
