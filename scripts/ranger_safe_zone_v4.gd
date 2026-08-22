extends "res://scripts/ranger_safe_zone_v3.gd"

# v0.63: safe-zone eviction must not mutate co-op Darkness state behind the
# owner. Routing through _despawn_shared_darkness preserves pacing RECOVERY,
# cooldown, and the single-owner rule introduced with LightRegistry.

func _enforce_coop_threat_state() -> void:
    if not _network_online():
        return
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return

    var tenant_target: int = int(coop.get("tenant_target_peer"))
    if bool(coop.get("tenant_active")) and tenant_target > 0 and _peer_is_safe(coop, tenant_target):
        if coop.has_method("request_tenant_stop"):
            coop.call("request_tenant_stop")

    var dark_target: int = int(coop.get("dark_target_peer"))
    if not bool(coop.get("dark_active")) or dark_target <= 0 or not _peer_is_safe(coop, dark_target):
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var hosting: bool = network != null and network.has_method("is_server") and bool(network.call("is_server"))
    if not hosting:
        return

    if coop.has_method("_despawn_shared_darkness"):
        coop.call("_despawn_shared_darkness", 4.0)
        if coop.has_method("_broadcast_monster_state"):
            coop.call("_broadcast_monster_state")
        return

    # Defensive fallback for an unexpected older co-op implementation.
    super._enforce_coop_threat_state()

func get_safe_zone_threat_contract_v63() -> Dictionary:
    return {
        "darkness_eviction_via_owner": true,
        "tenant_stop_via_owner": true,
        "powered_yard_required": true
    }
