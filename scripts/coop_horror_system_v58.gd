extends "res://scripts/coop_horror_system_v51.gd"

# v0.58: major co-op monsters share a high-level pacing budget so Tenant and
# Darkness Creature cannot begin as simultaneous full-pressure encounters.

func _server_start_tenant(trigger_peer_id: int) -> void:
    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing != null and pacing.has_method("can_start_major_threat"):
        if not bool(pacing.call("can_start_major_threat", "tenant")):
            return

    var was_active: bool = tenant_active
    super._server_start_tenant(trigger_peer_id)
    if not was_active and tenant_active and pacing != null and pacing.has_method("begin_major_threat"):
        pacing.call("begin_major_threat", "tenant")

func _server_stop_tenant() -> void:
    var was_active: bool = tenant_active
    super._server_stop_tenant()
    if was_active and not tenant_active:
        var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
        if pacing != null and pacing.has_method("end_major_threat"):
            pacing.call("end_major_threat", "tenant")

func _spawn_shared_darkness(target_peer_id: int) -> void:
    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing != null and pacing.has_method("can_start_major_threat"):
        if not bool(pacing.call("can_start_major_threat", "darkness")):
            dark_spawn_cooldown = maxf(dark_spawn_cooldown, 2.0)
            return

    var was_active: bool = dark_active
    super._spawn_shared_darkness(target_peer_id)
    if not was_active and dark_active and pacing != null and pacing.has_method("begin_major_threat"):
        pacing.call("begin_major_threat", "darkness")

func _despawn_shared_darkness(cooldown: float) -> void:
    var was_active: bool = dark_active
    super._despawn_shared_darkness(cooldown)
    if was_active and not dark_active:
        var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
        if pacing != null and pacing.has_method("end_major_threat"):
            pacing.call("end_major_threat", "darkness")
