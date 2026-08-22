extends "res://scripts/mine_power_system.gd"

# v0.58 co-op noise ownership fix. The base system validates the requesting
# peer correctly, but its generic noise helper uses the local host position.
# Preserve the validated peer context so AI noise originates at the actor who
# actually switched the circuit.

var request_peer_context_v58: int = 0

func _select_circuit_authoritative(circuit_id: String, peer_id: int) -> void:
    request_peer_context_v58 = peer_id
    super._select_circuit_authoritative(circuit_id, peer_id)
    request_peer_context_v58 = 0

func _report_power_noise() -> void:
    var relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if relay == null or not relay.has_method("report_noise"):
        return

    var origin: Vector3 = Vector3.ZERO
    var position_result: Dictionary = _peer_position(request_peer_context_v58)
    var position_value: Variant = position_result.get("position", null)
    if bool(position_result.get("valid", false)) and position_value is Vector3:
        origin = position_value
    else:
        var player: CharacterBody3D = _local_player()
        if player != null:
            origin = player.global_position

    relay.call("report_noise", origin, 0.92, "mine power routing")
