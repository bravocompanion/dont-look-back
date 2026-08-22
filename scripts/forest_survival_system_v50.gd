extends "res://scripts/forest_survival_system_v49.gd"

const WILDLIFE_V50_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v50.gd"

# v0.50: movement no longer adds separate fast sway waves on top of draw sway.
# Walking, sprinting and airborne movement each use the same +30% amplitude tier.
# The states intentionally do not stack, which prevents run/jump camera vibration.
@export var bow_movement_sway_bonus: float = 0.30
@export var bow_sway_smoothing_speed: float = 9.0

var bow_smoothed_camera_rotation: Vector3 = Vector3.ZERO
var bow_smoothed_camera_position: Vector3 = Vector3.ZERO

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V50_SCRIPT_PATH) as Script

func _apply_camera_draw_sway() -> void:
    if bow_draw_camera == null or not is_instance_valid(bow_draw_camera):
        return
    var player: CharacterBody3D = _local_player()
    if player == null:
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var walking_or_running: bool = horizontal_speed > 0.25
    var sprinting: bool = bool(player.get("is_sprinting"))
    var airborne: bool = not player.is_on_floor()

    # Walking, running/sprinting and jumping all get exactly +30% sway.
    # Multiple movement states do not stack; this is the anti-jitter change.
    var movement_active: bool = walking_or_running or sprinting or airborne
    var motion_multiplier: float = 1.0 + (bow_movement_sway_bonus if movement_active else 0.0)

    var overdraw_seconds: float = maxf(0.0, bow_draw_elapsed - bow_full_draw_seconds)
    var draw_amplitude_degrees: float = lerpf(
        bow_idle_camera_sway_degrees,
        bow_full_draw_camera_sway_degrees,
        bow_draw_power
    )
    draw_amplitude_degrees += minf(0.32, overdraw_seconds * 0.12)
    var amplitude_degrees: float = draw_amplitude_degrees * motion_multiplier

    # One coherent low-frequency procedural layer only. No extra stride/jump
    # oscillators are added, so locomotion and draw sway cannot fight each other.
    var phase: float = bow_sway_phase
    var target_rotation: Vector3 = Vector3(
        deg_to_rad(sin(phase * 1.85) * amplitude_degrees * 0.58),
        deg_to_rad(cos(phase * 2.27 + 0.72) * amplitude_degrees * 0.72),
        deg_to_rad(sin(phase * 1.31 + 1.10) * amplitude_degrees * 0.34)
    )

    var position_amplitude: float = bow_camera_position_sway_meters * (0.45 + bow_draw_power * 0.55) * motion_multiplier
    var target_position: Vector3 = Vector3(
        sin(phase * 2.15) * position_amplitude,
        cos(phase * 1.72 + 0.35) * position_amplitude * 0.70,
        0.0
    )

    var delta: float = maxf(0.0, get_process_delta_time())
    var smoothing_weight: float = clampf(delta * bow_sway_smoothing_speed, 0.0, 1.0)
    bow_smoothed_camera_rotation = bow_smoothed_camera_rotation.lerp(target_rotation, smoothing_weight)
    bow_smoothed_camera_position = bow_smoothed_camera_position.lerp(target_position, smoothing_weight)

    bow_applied_camera_rotation = bow_smoothed_camera_rotation
    bow_applied_camera_position = bow_smoothed_camera_position
    bow_draw_camera.rotation += bow_applied_camera_rotation
    bow_draw_camera.position += bow_applied_camera_position

func _finish_bow_draw_visuals() -> void:
    super._finish_bow_draw_visuals()
    bow_smoothed_camera_rotation = Vector3.ZERO
    bow_smoothed_camera_position = Vector3.ZERO
