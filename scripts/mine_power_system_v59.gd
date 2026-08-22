extends "res://scripts/mine_power_system_v58.gd"

# v0.59 persistence layer for the shared Mine support-light circuit.
# Checkpoint/world snapshots must restore the exact circuit that was active at
# checkpoint time so a wipe cannot silently keep a later routing choice.

func get_save_state() -> Dictionary:
    return {
        "current_circuit": current_circuit
    }

func restore_save_state(state: Dictionary) -> void:
    var restored: String = str(state.get("current_circuit", CIRCUIT_UPPER))
    if restored != CIRCUIT_UPPER and restored != CIRCUIT_DEEP:
        restored = CIRCUIT_UPPER
    current_circuit = restored
    if runtime_root != null and is_instance_valid(runtime_root):
        _apply_light_state()

func reset_progress() -> void:
    current_circuit = CIRCUIT_UPPER
    if runtime_root != null and is_instance_valid(runtime_root):
        _apply_light_state()
