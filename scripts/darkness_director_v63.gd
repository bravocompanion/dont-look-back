extends "res://scripts/darkness_director.gd"

# v0.63 ownership rule:
# - offline: this director is the only Darkness spawner;
# - online: CoopHorrorSystem/host is the only Darkness owner.
# The director therefore performs no spawn/update work while network play is active.

var solo_darkness_active_v63: bool = false

func _process(delta: float) -> void:
    if _network_online_v63():
        return

    spawn_cooldown = maxf(0.0, spawn_cooldown - delta)
    var creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if creature != null:
        solo_darkness_active_v63 = true
        return

    if solo_darkness_active_v63:
        solo_darkness_active_v63 = false
        var ending_pacing: Node = get_node_or_null("/root/HorrorPacingSystem")
        if ending_pacing != null and ending_pacing.has_method("end_major_threat"):
            ending_pacing.call("end_major_threat", "darkness")

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not player.has_method("get_darkness_exposure"):
        return

    var exposure: float = float(player.call("get_darkness_exposure"))
    var in_light: bool = _player_protected_from_darkness_v63(player)
    _report_pressure_v63(exposure, in_light)

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
    solo_darkness_active_v63 = true

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Something is forming in the dark. GET TO THE LIGHT."

func get_runtime_owner_v63() -> String:
    return resolve_owner_for_mode_v63(_network_online_v63())

func resolve_owner_for_mode_v63(online: bool) -> String:
    return "coop_host" if online else "solo_director"

func solo_spawn_allowed_for_mode_v63(online: bool) -> bool:
    return not online

func _player_protected_from_darkness_v63(player: CharacterBody3D) -> bool:
    var registry: Node = get_node_or_null("/root/LightRegistry")
    if registry != null and registry.has_method("is_player_protected_from_darkness_v63"):
        return bool(registry.call("is_player_protected_from_darkness_v63", player))
    return player.has_method("is_in_light") and bool(player.call("is_in_light"))

func _report_pressure_v63(exposure: float, in_light: bool) -> void:
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

func _network_online_v63() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
