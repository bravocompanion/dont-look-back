extends "res://scripts/darkness_director.gd"

# v0.62 solo integration. Co-op keeps its existing shared horror ownership;
# offline Darkness now announces rising pressure to HorrorPacingSystem and must
# acquire the shared major-threat budget before spawning.

var solo_darkness_active_v62: bool = false

func _process(delta: float) -> void:
    if _network_online_v62():
        super._process(delta)
        return

    spawn_cooldown = maxf(0.0, spawn_cooldown - delta)
    var creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if creature != null:
        solo_darkness_active_v62 = true
        return

    if solo_darkness_active_v62:
        solo_darkness_active_v62 = false
        var ending_pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
        if ending_pacing != null and ending_pacing.has_method("end_major_threat"):
            ending_pacing.call("end_major_threat", "darkness")

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not player.has_method("get_darkness_exposure") or not player.has_method("is_in_light"):
        return

    var exposure: float = float(player.call("get_darkness_exposure"))
    var in_light: bool = bool(player.call("is_in_light"))
    _report_pressure_v62(exposure, in_light)

    if player.global_position.z > minimum_player_z or spawn_cooldown > 0.0 or in_light or exposure < spawn_threshold:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or creature_script == null:
        return

    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing != null and pacing.has_method("begin_major_threat"):
        if not bool(pacing.call("begin_major_threat", "darkness")):
            return

    var spawn_position: Vector3 = _find_spawn_position(player)
    var spawned: Node3D = Node3D.new()
    spawned.name = "DarknessCreature"
    spawned.set_script(creature_script)
    scene.add_child(spawned)
    spawned.global_position = spawn_position
    spawn_cooldown = spawn_cooldown_seconds
    solo_darkness_active_v62 = true

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Something is forming in the dark. GET TO THE LIGHT."

func _report_pressure_v62(exposure: float, in_light: bool) -> void:
    if in_light:
        return
    var pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
    if pacing == null:
        return
    var ratio: float = exposure / maxf(spawn_threshold, 1.0)
    if ratio >= 0.80 and pacing.has_method("request_stalk_v62"):
        pacing.call("request_stalk_v62", "darkness exposure", 3.5, clampf(0.58 + ratio * 0.18, 0.68, 0.88))
    elif ratio >= 0.55 and pacing.has_method("request_unease_v62"):
        pacing.call("request_unease_v62", "darkness exposure", clampf(ratio * 0.55, 0.30, 0.52), 3.0)

func _network_online_v62() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
