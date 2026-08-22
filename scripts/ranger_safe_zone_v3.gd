extends "res://scripts/ranger_safe_zone_v2.gd"

# v0.56: the ranger yard is no longer an unconditional monster-proof box.
# Full yard protection exists only while the shelter generator is running or
# the campfire is still burning. Flashlights are intentionally excluded.

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        _restore_solo_directors()
        return

    var yard_powered: bool = _yard_protection_active_v56()
    var local_player: CharacterBody3D = _local_player()
    var local_safe: bool = local_player != null and yard_powered and is_position_safe(local_player.global_position)

    if local_safe:
        _protect_player(local_player)

    _enforce_solo_threat_state(scene, local_safe)
    _enforce_coop_threat_state()

    # Only evict threats while the yard protection source is actually active.
    # When both generator and campfire are out, hostiles may enter the yard.
    if yard_powered:
        _evict_group("darkness_creature", true)
        _evict_group("coop_darkness_creature", true)
        _evict_group("wildlife", false)
        _evict_group("enemy", false)
        _evict_group("hostile", false)
        _evict_group("monster", false)
        _evict_group("tenant", false)
        _evict_group("warden", false)
        _evict_named_tenant(scene, local_safe)

    # Resource relocation remains geometric rather than power-dependent so
    # supplies never spawn inside the cabin yard and become free shelter loot.
    resource_scan_timer -= delta
    if resource_scan_timer <= 0.0:
        resource_scan_timer = RESOURCE_SCAN_INTERVAL
        _relocate_dynamic_resources(scene)

func is_player_safe(player: Node3D) -> bool:
    return (
        player != null
        and _yard_protection_active_v56()
        and is_position_safe(player.global_position)
    )

func is_threat_protected_position_v56(world_position: Vector3) -> bool:
    return _yard_protection_active_v56() and is_position_safe(world_position)

func _peer_is_safe(coop: Node, peer_id: int) -> bool:
    if not _yard_protection_active_v56() or peer_id <= 0:
        return false
    return super._peer_is_safe(coop, peer_id)

func _yard_protection_active_v56() -> bool:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return false

    var generator_on: bool = false
    if shelter.has_method("is_generator_running"):
        generator_on = bool(shelter.call("is_generator_running"))
    else:
        generator_on = bool(shelter.get("generator_running"))
    if generator_on:
        return true

    return float(shelter.get("campfire_burn_seconds")) > 0.05
