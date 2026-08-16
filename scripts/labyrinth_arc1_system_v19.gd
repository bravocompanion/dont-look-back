extends "res://scripts/labyrinth_arc1_system.gd"

@rpc("authority", "call_remote", "reliable", 8)
func _receive_arc_state(state: Dictionary) -> void:
    pending_restore_state = state.duplicate(true)
    super._receive_arc_state(state)
