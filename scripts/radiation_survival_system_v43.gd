extends "res://scripts/radiation_survival_system_v42.gd"

# v0.55 P1 radiation upkeep. A carried Radiation Suit remains useful, but its
# filter gradually degrades while the survivor is actually exposed to the
# Day-3+ forest radiation field. Industrial Filters restore the cartridge.
@export var suit_filter_max_charge_v55: float = 100.0
@export var suit_filter_base_drain_per_second_v55: float = 0.14
@export var suit_full_filter_multiplier_v55: float = 0.22
@export var suit_empty_filter_multiplier_v55: float = 0.70

var suit_filter_charge_v55: float = 100.0
var filter_warning_band_v55: int = 3

func get_suit_filter_charge_v55() -> float:
    return clampf(suit_filter_charge_v55, 0.0, suit_filter_max_charge_v55)

func get_suit_filter_percent_v55() -> int:
    if suit_filter_max_charge_v55 <= 0.0:
        return 0
    return int(round(clampf(suit_filter_charge_v55 / suit_filter_max_charge_v55, 0.0, 1.0) * 100.0))

func replace_suit_filter_v55(player: CharacterBody3D) -> bool:
    if player == null or not player.has_method("has_item") or not player.has_method("remove_item"):
        return false
    if not bool(player.call("has_item", "radiation_suit")):
        _filter_feedback_v55(player, "A Radiation Suit is required before installing a filter cartridge.")
        return false
    if suit_filter_charge_v55 >= suit_filter_max_charge_v55 - 1.0:
        _filter_feedback_v55(player, "The Radiation Suit filter is already near full capacity.")
        return false
    if not bool(player.call("remove_item", "filter")):
        _filter_feedback_v55(player, "You need an Industrial Filter to replace the Radiation Suit cartridge.")
        return false

    suit_filter_charge_v55 = suit_filter_max_charge_v55
    filter_warning_band_v55 = 3
    _filter_feedback_v55(player, "Radiation Suit filter replaced — cartridge charge restored to 100%.")
    _request_autosave("Radiation Suit filter replaced")
    return true

func get_save_state() -> Dictionary:
    var state: Dictionary = super.get_save_state()
    state["suit_filter_charge_v55"] = suit_filter_charge_v55
    return state

func restore_save_state(state: Dictionary) -> void:
    super.restore_save_state(state)
    suit_filter_charge_v55 = clampf(
        float(state.get("suit_filter_charge_v55", suit_filter_max_charge_v55)),
        0.0,
        suit_filter_max_charge_v55
    )
    filter_warning_band_v55 = _filter_band_v55(get_suit_filter_percent_v55())

func reset_progress() -> void:
    super.reset_progress()
    suit_filter_charge_v55 = suit_filter_max_charge_v55
    filter_warning_band_v55 = 3

func _update_radiation(player: CharacterBody3D, scene: Node, delta: float) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1

    if scene.scene_file_path != FOREST_SCENE_PATH or day_index < RADIATION_START_DAY:
        radiation_rate = -0.45
        radiation = maxf(0.0, radiation + radiation_rate * delta)
        return

    if is_position_protected(player.global_position):
        radiation_rate = -1.20
        radiation = maxf(0.0, radiation + radiation_rate * delta)
        return

    var weather_multiplier: float = _weather_multiplier_v55()
    var base_rate: float = _base_radiation_rate_v55(day_index)
    var gear_multiplier: float = 1.0
    if _player_has_suit_v55(player):
        _drain_suit_filter_v55(player, delta, day_index, weather_multiplier)
        gear_multiplier = _suit_multiplier_v55()

    radiation_rate = base_rate * weather_multiplier * gear_multiplier
    radiation = minf(100.0, radiation + radiation_rate * delta)

func _advance_sleep_radiation_v54(
    player: CharacterBody3D,
    delta: float,
    simulated_day_index: int,
    generator_protected: bool
) -> void:
    if simulated_day_index < RADIATION_START_DAY:
        radiation_rate = -0.45
        radiation = maxf(0.0, radiation + radiation_rate * delta)
    elif generator_protected:
        radiation_rate = -1.20
        radiation = maxf(0.0, radiation + radiation_rate * delta)
    else:
        var weather_multiplier: float = _weather_multiplier_v55()
        var gear_multiplier: float = 1.0
        if _player_has_suit_v55(player):
            _drain_suit_filter_v55(player, delta, simulated_day_index, weather_multiplier)
            gear_multiplier = _suit_multiplier_v55()
        radiation_rate = _base_radiation_rate_v55(simulated_day_index) * weather_multiplier * gear_multiplier
        radiation = minf(100.0, radiation + radiation_rate * delta)

    if radiation >= 35.0:
        player.set("stamina", maxf(0.0, float(player.get("stamina")) - 0.08 * delta))
    if radiation >= 55.0:
        player.set("thirst", maxf(0.0, float(player.get("thirst")) - 0.035 * delta))

    damage_timer -= delta
    if damage_timer > 0.0:
        return
    damage_timer = 3.0

    var damage: float = 0.0
    if radiation >= 90.0:
        damage = 5.0
    elif radiation >= 72.0:
        damage = 2.5
    if damage > 0.0 and player.has_method("apply_damage"):
        player.call("apply_damage", damage, "radiation exposure during sleep")

func _drain_suit_filter_v55(
    player: CharacterBody3D,
    delta: float,
    day_index: int,
    weather_multiplier: float
) -> void:
    if delta <= 0.0 or suit_filter_charge_v55 <= 0.0:
        return
    var day_pressure: float = 1.0 + maxf(0.0, float(day_index - RADIATION_START_DAY)) * 0.12
    suit_filter_charge_v55 = maxf(
        0.0,
        suit_filter_charge_v55 - suit_filter_base_drain_per_second_v55 * day_pressure * weather_multiplier * delta
    )
    _update_filter_warning_v55(player)

func _suit_multiplier_v55() -> float:
    var ratio: float = 0.0
    if suit_filter_max_charge_v55 > 0.0:
        ratio = clampf(suit_filter_charge_v55 / suit_filter_max_charge_v55, 0.0, 1.0)
    return lerpf(suit_empty_filter_multiplier_v55, suit_full_filter_multiplier_v55, ratio)

func _player_has_suit_v55(player: CharacterBody3D) -> bool:
    return player != null and player.has_method("has_item") and bool(player.call("has_item", "radiation_suit"))

func _base_radiation_rate_v55(day_index: int) -> float:
    if day_index <= 3:
        return 0.10
    if day_index == 4:
        return 0.14
    return minf(0.32, 0.18 + float(day_index - 5) * 0.018)

func _weather_multiplier_v55() -> float:
    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime == null:
        return 1.0
    var weather: String = str(forest_runtime.get("current_weather"))
    if weather == "rain":
        return 1.12
    if weather == "storm":
        return 1.35
    return 1.0

func _update_filter_warning_v55(player: CharacterBody3D) -> void:
    var percent: int = get_suit_filter_percent_v55()
    var band: int = _filter_band_v55(percent)
    if band >= filter_warning_band_v55:
        return
    filter_warning_band_v55 = band
    if band == 2:
        _filter_feedback_v55(player, "Radiation Suit filter at 50%. Carry an Industrial Filter before the next long expedition.")
    elif band == 1:
        _filter_feedback_v55(player, "Radiation Suit filter critical — below 25%. Shielding efficiency is falling.")
    else:
        _filter_feedback_v55(player, "Radiation Suit filter exhausted. The suit still shields partially, but radiation penetrates much faster.")

func _filter_band_v55(percent: int) -> int:
    if percent <= 0:
        return 0
    if percent <= 25:
        return 1
    if percent <= 50:
        return 2
    return 3

func _filter_feedback_v55(player: CharacterBody3D, text: String) -> void:
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text
