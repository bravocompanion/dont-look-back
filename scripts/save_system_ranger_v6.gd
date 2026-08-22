extends "res://scripts/save_system_ranger_v5.gd"

# v0.59 checkpoint consistency:
# - checkpoint snapshots include shared world/progression/finite-loot state;
# - the checkpoint's own snapshot is excluded from the nested snapshot to avoid
#   recursive save data;
# - Mine power routing is now part of normal save/checkpoint persistence.

const CHECKPOINT_SNAPSHOT_VERSION_V59: int = 1

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    var mine_power: Node = get_node_or_null("/root/MinePowerSystem")
    if mine_power != null and mine_power.has_method("get_save_state"):
        var mine_value: Variant = mine_power.call("get_save_state")
        if mine_value is Dictionary:
            state["mine_power_v59"] = Dictionary(mine_value).duplicate(true)
    return state

func _prepare_clean_reload() -> void:
    super._prepare_clean_reload()
    var mine_power: Node = get_node_or_null("/root/MinePowerSystem")
    if mine_power != null and mine_power.has_method("reset_progress"):
        mine_power.call("reset_progress")

func _restore_state(state: Dictionary) -> void:
    super._restore_state(state)

    var mine_power: Node = get_node_or_null("/root/MinePowerSystem")
    var mine_value: Variant = state.get("mine_power_v59", {})
    if mine_power != null and mine_power.has_method("restore_save_state") and mine_value is Dictionary:
        mine_power.call("restore_save_state", Dictionary(mine_value))

    call_deferred("_backfill_legacy_checkpoint_snapshot_v59")

func build_checkpoint_shared_snapshot(player: CharacterBody3D) -> Dictionary:
    if player == null:
        return {}
    _merge_network_claims()
    var snapshot: Dictionary = _collect_state(player).duplicate(true)
    snapshot["checkpoint_snapshot_version_v59"] = CHECKPOINT_SNAPSHOT_VERSION_V59
    # The outer checkpoint already stores this snapshot. Never nest it again.
    snapshot["checkpoint"] = {}
    return snapshot

func restore_checkpoint_shared_snapshot(snapshot: Dictionary) -> bool:
    if snapshot.is_empty():
        return false

    var migrated: Dictionary = snapshot.duplicate(true)
    var local_player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D

    # Shared rollback must not overwrite the local survivor checkpoint payload;
    # CheckpointSystem restores that immediately after this world restore.
    migrated["checkpoint"] = _collect_checkpoint_state()
    if local_player != null:
        migrated["player"] = _collect_player_state(local_player)

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        network.set("pending_pickups", {})

    _restore_state(migrated)

    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing != null and pacing.has_method("force_recovery"):
        pacing.call("force_recovery", 8.0, "checkpoint")
    return true

func _collect_checkpoint_state() -> Dictionary:
    var state: Dictionary = super._collect_checkpoint_state()
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null:
        return state

    var scene_path_value: Variant = checkpoint.get("checkpoint_scene_path_v59")
    if scene_path_value != null:
        state["scene_path_v59"] = str(scene_path_value)

    var snapshot_value: Variant = checkpoint.get("shared_snapshot_v59")
    if snapshot_value is Dictionary:
        var shared: Dictionary = Dictionary(snapshot_value)
        if not shared.is_empty():
            state["shared_snapshot_v59"] = shared.duplicate(true)
            state["snapshot_version_v59"] = CHECKPOINT_SNAPSHOT_VERSION_V59
    return state

func _restore_checkpoint_state(state: Dictionary) -> void:
    super._restore_checkpoint_state(state)
    if state.is_empty():
        return

    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null:
        return

    if checkpoint.get("checkpoint_scene_path_v59") != null:
        checkpoint.set("checkpoint_scene_path_v59", str(state.get("scene_path_v59", _current_map_scene_path())))
    if checkpoint.get("shared_snapshot_v59") != null:
        var snapshot_value: Variant = state.get("shared_snapshot_v59", {})
        checkpoint.set(
            "shared_snapshot_v59",
            Dictionary(snapshot_value).duplicate(true) if snapshot_value is Dictionary else {}
        )

func _backfill_legacy_checkpoint_snapshot_v59() -> void:
    await get_tree().process_frame
    await get_tree().process_frame

    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null or not bool(checkpoint.get("checkpoint_active")):
        return
    var existing_value: Variant = checkpoint.get("shared_snapshot_v59")
    if existing_value is Dictionary and not Dictionary(existing_value).is_empty():
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var snapshot: Dictionary = build_checkpoint_shared_snapshot(player)
    if not snapshot.is_empty():
        checkpoint.set("shared_snapshot_v59", snapshot)
        if checkpoint.get("checkpoint_scene_path_v59") != null:
            checkpoint.set("checkpoint_scene_path_v59", _current_map_scene_path())
