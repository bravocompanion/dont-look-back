extends "res://scripts/horror_pacing_system.gd"

# v0.62: readable CALM -> UNEASE -> STALK -> HUNT -> RECOVERY budget.
# Monster movement/combat remains owned by the existing threat systems.

const STATE_CALM: String = "CALM"
const STATE_UNEASE: String = "UNEASE"
const STATE_STALK: String = "STALK"
const STATE_HUNT: String = "HUNT"
const STATE_RECOVERY: String = "RECOVERY"
const RESCUE_SAFE_RECOVERY_MULTIPLIER: float = 1.45
const ANOMALY_HINT_COOLDOWN: float = 10.0

var pacing_state_v62: String = STATE_CALM
var pressure_v62: float = 0.0
var unease_remaining_v62: float = 0.0
var stalk_remaining_v62: float = 0.0
var anomaly_hint_cooldown_v62: float = 0.0
var last_reason_v62: String = ""

func _process(delta: float) -> void:
    var recovery_before: float = recovery_remaining
    super._process(delta)
    unease_remaining_v62 = maxf(0.0, unease_remaining_v62 - delta)
    stalk_remaining_v62 = maxf(0.0, stalk_remaining_v62 - delta)
    anomaly_hint_cooldown_v62 = maxf(0.0, anomaly_hint_cooldown_v62 - delta)

    # Rescue Priority rewards actually returning to a powered shelter instead
    # of granting a global stat buff.
    if recovery_before > 0.0 and recovery_remaining > 0.0 and _rescue_priority_active_v62() and _local_player_in_protected_shelter_v62():
        recovery_remaining = maxf(0.0, recovery_remaining - delta * (RESCUE_SAFE_RECOVERY_MULTIPLIER - 1.0))

    var desired: String = STATE_CALM
    if not current_major_threat.is_empty():
        desired = STATE_HUNT
        pressure_v62 = 1.0
    elif recovery_remaining > 0.0:
        desired = STATE_RECOVERY
        pressure_v62 = move_toward(pressure_v62, 0.22, delta * 0.18)
    elif stalk_remaining_v62 > 0.0:
        desired = STATE_STALK
        pressure_v62 = maxf(pressure_v62, 0.68)
    elif unease_remaining_v62 > 0.0:
        desired = STATE_UNEASE
        pressure_v62 = maxf(pressure_v62, 0.34)
    else:
        pressure_v62 = move_toward(pressure_v62, 0.0, delta * 0.10)
        if pressure_v62 >= 0.55:
            desired = STATE_STALK
        elif pressure_v62 >= 0.18:
            desired = STATE_UNEASE
    _set_state_v62(desired)

func request_unease_v62(source: String, strength: float = 0.30, duration: float = 6.0) -> void:
    if not current_major_threat.is_empty() or recovery_remaining > 0.0:
        return
    pressure_v62 = maxf(pressure_v62, clampf(strength, 0.0, 0.64))
    unease_remaining_v62 = maxf(unease_remaining_v62, maxf(0.0, duration))
    if not source.is_empty():
        last_reason_v62 = source

func request_stalk_v62(source: String, duration: float = 7.0, pressure: float = 0.72) -> void:
    if not current_major_threat.is_empty() or recovery_remaining > 0.0:
        return
    pressure_v62 = maxf(pressure_v62, clampf(pressure, 0.55, 0.94))
    stalk_remaining_v62 = maxf(stalk_remaining_v62, maxf(0.0, duration))
    unease_remaining_v62 = maxf(unease_remaining_v62, duration)
    if not source.is_empty():
        last_reason_v62 = source

func begin_major_threat(threat_id: String) -> bool:
    var accepted: bool = super.begin_major_threat(threat_id)
    if accepted:
        pressure_v62 = 1.0
        unease_remaining_v62 = 0.0
        stalk_remaining_v62 = 0.0
        last_reason_v62 = threat_id
        _set_state_v62(STATE_HUNT)
    return accepted

func end_major_threat(threat_id: String, recovery_seconds: float = -1.0) -> void:
    var was_active: bool = current_major_threat == threat_id
    super.end_major_threat(threat_id, recovery_seconds)
    if was_active:
        pressure_v62 = maxf(pressure_v62, 0.72)
        _set_state_v62(STATE_RECOVERY)

func force_recovery(seconds: float, source: String = "system") -> void:
    super.force_recovery(seconds, source)
    pressure_v62 = maxf(pressure_v62, 0.56)
    unease_remaining_v62 = 0.0
    stalk_remaining_v62 = 0.0
    last_reason_v62 = source
    _set_state_v62(STATE_RECOVERY)

func reset_pacing_v62() -> void:
    current_major_threat = ""
    recovery_remaining = 0.0
    recovery_source = ""
    pacing_state_v62 = STATE_CALM
    pressure_v62 = 0.0
    unease_remaining_v62 = 0.0
    stalk_remaining_v62 = 0.0
    anomaly_hint_cooldown_v62 = 0.0
    last_reason_v62 = ""

func get_state_name_v62() -> String:
    return pacing_state_v62

func get_pressure_v62() -> float:
    return clampf(pressure_v62, 0.0, 1.0)

func get_last_reason_v62() -> String:
    return last_reason_v62

func get_safe_recovery_multiplier_v62() -> float:
    return RESCUE_SAFE_RECOVERY_MULTIPLIER if _rescue_priority_active_v62() else 1.0

func anomaly_analysis_active_v62() -> bool:
    return _anomaly_priority_active_v62()

func _set_state_v62(next_state: String) -> void:
    if next_state == pacing_state_v62:
        return
    pacing_state_v62 = next_state
    # Containment Data is an information reward, not a damage buff.
    if _anomaly_priority_active_v62() and anomaly_hint_cooldown_v62 <= 0.0:
        anomaly_hint_cooldown_v62 = ANOMALY_HINT_COOLDOWN
        match next_state:
            STATE_UNEASE:
                _objective_v62("ANOMALY ANALYSIS: environmental pressure rising — no confirmed entity.")
            STATE_STALK:
                _objective_v62("ANOMALY ANALYSIS: stalking pattern probable. Secure a light route.")
            STATE_HUNT:
                _objective_v62("ANOMALY ANALYSIS: major threat signature CONFIRMED.")
            STATE_RECOVERY:
                _objective_v62("ANOMALY ANALYSIS: threat signature falling. Recovery window open.")

func _research_payoff_v62() -> Node:
    return get_node_or_null("/root/ResearchFacilityPayoffSystem")

func _rescue_priority_active_v62() -> bool:
    var payoff: Node = _research_payoff_v62()
    return payoff != null and payoff.has_method("has_rescue_priority_v62") and bool(payoff.call("has_rescue_priority_v62"))

func _anomaly_priority_active_v62() -> bool:
    var payoff: Node = _research_payoff_v62()
    return payoff != null and payoff.has_method("has_anomaly_priority_v62") and bool(payoff.call("has_anomaly_priority_v62"))

func _local_player_in_protected_shelter_v62() -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != "res://scenes/forest.tscn":
        return false
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return false
    var safe_zone: Node = get_node_or_null("/root/RangerSafeZone")
    return safe_zone != null and safe_zone.has_method("is_position_safe") and bool(safe_zone.call("is_position_safe", player.global_position))

func _objective_v62(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text
