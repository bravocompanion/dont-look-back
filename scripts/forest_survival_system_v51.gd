extends "res://scripts/forest_survival_system_v50.gd"

const WILDLIFE_V51_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v51.gd"

# v0.51 bow feel:
# - walk sway +25%
# - sprint/run sway +40%
# - one smooth jump kick at +50% strength (no extra oscillator)
# - full draw reduces FOV by 30%
@export var bow_walk_sway_bonus: float = 0.25
@export var bow_run_sway_bonus: float = 0.40
@export var bow_jump_kick_bonus: float = 0.50
@export var bow_jump_kick_decay_speed: float = 5.5
@export var bow_full_draw_zoom_fraction: float = 0.30
@export var bow_zoom_smoothing_speed: float = 8.5

var bow_was_airborne_v51: bool = false
var bow_jump_kick_strength_v51: float = 0.0

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V51_SCRIPT_PATH) as Script

func _begin_bow_draw() -> void:
    super._begin_bow_draw()
    if bow_drawing:
        # The inherited v0.45 draw controller also owns an FOV target. Point it
        # at the same 30% zoom target so two smoothing passes never fight.
        bow_draw_fov_reduction = bow_base_fov * bow_full_draw_zoom_fraction
        var player: CharacterBody3D = _local_player()
        bow_was_airborne_v51 = player != null and not player.is_on_floor()
        bow_jump_kick_strength_v51 = 0.0

func _update_bow_draw(delta: float) -> void:
    super._update_bow_draw(delta)
    if not bow_drawing or bow_draw_camera == null or not is_instance_valid(bow_draw_camera):
        return

    # Full draw = 30% lower FOV than the original camera FOV.
    var zoom_fraction: float = clampf(bow_full_draw_zoom_fraction * bow_draw_power, 0.0, 0.60)
    var target_fov: float = bow_base_fov * (1.0 - zoom_fraction)
    bow_draw_camera.fov = lerpf(
        bow_draw_camera.fov,
        target_fov,
        clampf(delta * bow_zoom_smoothing_speed, 0.0, 1.0)
    )

func _apply_camera_draw_sway() -> void:
    if bow_draw_camera == null or not is_instance_valid(bow_draw_camera):
        return
    var player: CharacterBody3D = _local_player()
    if player == null:
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var sprinting: bool = bool(player.get("is_sprinting")) and horizontal_speed > 0.25
    var walking: bool = horizontal_speed > 0.25 and not sprinting
    var airborne: bool = not player.is_on_floor()

    var movement_multiplier: float = 1.0
    if sprinting:
        movement_multiplier += bow_run_sway_bonus
    elif walking:
        movement_multiplier += bow_walk_sway_bonus

    # Trigger one jump impulse only when leaving the ground upward. It decays
    # smoothly instead of adding another periodic wave, preventing camera jitter.
    if airborne and not bow_was_airborne_v51 and player.velocity.y > 0.20:
        bow_jump_kick_strength_v51 = bow_jump_kick_bonus
    bow_was_airborne_v51 = airborne

    var delta: float = maxf(0.0, get_process_delta_time())
    bow_jump_kick_strength_v51 = move_toward(
        bow_jump_kick_strength_v51,
        0.0,
        bow_jump_kick_decay_speed * delta
    )

    var overdraw_seconds: float = maxf(0.0, bow_draw_elapsed - bow_full_draw_seconds)
    var draw_amplitude_degrees: float = lerpf(
        bow_idle_camera_sway_degrees,
        bow_full_draw_camera_sway_degrees,
        bow_draw_power
    )
    draw_amplitude_degrees += minf(0.32, overdraw_seconds * 0.12)
    var amplitude_degrees: float = draw_amplitude_degrees * movement_multiplier

    # One coherent low-frequency draw sway layer.
    var phase: float = bow_sway_phase
    var target_rotation: Vector3 = Vector3(
        deg_to_rad(sin(phase * 1.85) * amplitude_degrees * 0.58),
        deg_to_rad(cos(phase * 2.27 + 0.72) * amplitude_degrees * 0.72),
        deg_to_rad(sin(phase * 1.31 + 1.10) * amplitude_degrees * 0.34)
    )

    var position_amplitude: float = bow_camera_position_sway_meters * (0.45 + bow_draw_power * 0.55) * movement_multiplier
    var target_position: Vector3 = Vector3(
        sin(phase * 2.15) * position_amplitude,
        cos(phase * 1.72 + 0.35) * position_amplitude * 0.70,
        0.0
    )

    # The 50% jump kick is additive and non-periodic: a short upward/backward
    # body impulse while drawing, then a smooth return to the base sway curve.
    if bow_jump_kick_strength_v51 > 0.001:
        var kick_degrees: float = draw_amplitude_degrees * bow_jump_kick_strength_v51
        target_rotation.x -= deg_to_rad(kick_degrees * 0.95)
        target_rotation.z += deg_to_rad(kick_degrees * 0.32)
        target_position.y += bow_camera_position_sway_meters * bow_jump_kick_strength_v51 * 1.6
        target_position.z += bow_camera_position_sway_meters * bow_jump_kick_strength_v51 * 0.8

    var smoothing_weight: float = clampf(delta * bow_sway_smoothing_speed, 0.0, 1.0)
    bow_smoothed_camera_rotation = bow_smoothed_camera_rotation.lerp(target_rotation, smoothing_weight)
    bow_smoothed_camera_position = bow_smoothed_camera_position.lerp(target_position, smoothing_weight)

    bow_applied_camera_rotation = bow_smoothed_camera_rotation
    bow_applied_camera_position = bow_smoothed_camera_position
    bow_draw_camera.rotation += bow_applied_camera_rotation
    bow_draw_camera.position += bow_applied_camera_position

func _finish_bow_draw_visuals() -> void:
    super._finish_bow_draw_visuals()
    bow_was_airborne_v51 = false
    bow_jump_kick_strength_v51 = 0.0
