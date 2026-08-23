extends "res://scripts/outside_director_ranger_v7.gd"

# v0.66: use the current 18:30 visual level as the darkest readable Forest
# baseline. Gameplay daylight still reaches 0.0 at night; this only clamps the
# visual WorldEnvironment so Darkness/Tenant timing and protection stay intact.
const NIGHT_REFERENCE_MINUTES_V66: float = 1110.0 # 18:30
const NIGHT_REFERENCE_DAYLIGHT_V66: float = 0.25
const NIGHT_AMBIENT_FLOOR_V66: float = 0.08355
const NIGHT_NEUTRALIZE_START_DAYLIGHT_V66: float = 0.50
const NIGHT_BACKGROUND_COLOR_V66: Color = Color(0.045, 0.055, 0.073, 1.0)
const NIGHT_AMBIENT_COLOR_V66: Color = Color(0.19, 0.22, 0.27, 1.0)

func _apply_v184_celestial_lighting() -> void:
    super._apply_v184_celestial_lighting()
    if world_environment == null or world_environment.environment == null:
        return

    var daylight: float = _get_daylight_factor()
    if daylight > NIGHT_NEUTRALIZE_START_DAYLIGHT_V66:
        return

    var environment: Environment = world_environment.environment

    # Fade the warm sunset/sunrise tint out between 50% and 25% daylight so
    # the 18:30 threshold is already fully neutral instead of red/orange.
    var neutral_weight: float = clampf(
        (NIGHT_NEUTRALIZE_START_DAYLIGHT_V66 - daylight)
        / (NIGHT_NEUTRALIZE_START_DAYLIGHT_V66 - NIGHT_REFERENCE_DAYLIGHT_V66),
        0.0,
        1.0
    )
    environment.background_color = environment.background_color.lerp(
        NIGHT_BACKGROUND_COLOR_V66,
        neutral_weight
    )
    environment.ambient_light_color = environment.ambient_light_color.lerp(
        NIGHT_AMBIENT_COLOR_V66,
        neutral_weight
    )

    # At 18:30 daylight is 0.25 and the active v0.29+ curve produces about
    # 0.08355 ambient energy. Never let the visual world fall below that after
    # this point (or during the matching pre-dawn range).
    if daylight <= NIGHT_REFERENCE_DAYLIGHT_V66:
        environment.ambient_light_energy = maxf(
            environment.ambient_light_energy,
            NIGHT_AMBIENT_FLOOR_V66
        )

func get_night_visibility_contract_v66() -> Dictionary:
    return {
        "reference_time_minutes": NIGHT_REFERENCE_MINUTES_V66,
        "reference_time_label": "18:30",
        "reference_daylight": NIGHT_REFERENCE_DAYLIGHT_V66,
        "ambient_floor": NIGHT_AMBIENT_FLOOR_V66,
        "neutral_background": NIGHT_BACKGROUND_COLOR_V66,
        "neutral_ambient": NIGHT_AMBIENT_COLOR_V66,
        "red_twilight_at_or_below_reference": false,
        "changes_gameplay_daylight": false,
        "changes_daylight_protection": false,
        "changes_night_threat_rules": false
    }
