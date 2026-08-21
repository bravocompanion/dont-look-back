extends "res://scripts/forest_survival_system_v46.gd"

const WILDLIFE_V48_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v48.gd"

@export var bow_idle_camera_sway_degrees: float = 0.22
@export var bow_full_draw_camera_sway_degrees: float = 0.48
@export var bow_sprint_sway_bonus: float = 0.85
@export var bow_airborne_sway_bonus: float = 1.20
@export var bow_camera_position_sway_meters: float = 0.008

var bow_applied_camera_rotation: Vector3 = Vector3.ZERO
var bow_applied_camera_position: Vector3 = Vector3.ZERO

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V48_SCRIPT_PATH) as Script

func _build_ui() -> void:
    super._build_ui()
    if draw_aim_marker != null:
        draw_aim_marker.visible = false
        draw_aim_marker.text = ""

func _update_bow_draw(delta: float) -> void:
    # Remove the previous procedural offset before the inherited draw system reads
    # the camera again. Mouse/touch look that happened since the last frame remains,
    # while our own sway never accumulates into permanent camera drift.
    _remove_camera_draw_sway()
    super._update_bow_draw(delta)
    if bow_drawing:
        _apply_camera_draw_sway()

func _set_draw_ui_visible(value: bool) -> void:
    # Keep the power/readout UI, but the old fake moving aim marker is disabled.
    if draw_power_bar != null:
        draw_power_bar.visible = value
    if draw_power_label != null:
        draw_power_label.visible = value
    if draw_aim_marker != null:
        draw_aim_marker.visible = false

func _update_sway_marker() -> void:
    # v0.48 sway is physical camera/head motion, not a moving HUD reticle.
    if draw_aim_marker != null:
        draw_aim_marker.visible = false

func _current_swayed_direction(camera: Camera3D, _power: float) -> Vector3:
    # The camera itself already contains the current sway offset. Projectile aim
    # therefore follows what the player actually sees instead of a separate marker.
    return -camera.global_transform.basis.z.normalized()

func _finish_bow_draw_visuals() -> void:
    _remove_camera_draw_sway()
    super._finish_bow_draw_visuals()

func _apply_camera_draw_sway() -> void:
    if bow_draw_camera == null or not is_instance_valid(bow_draw_camera):
        return
    var player: CharacterBody3D = _local_player()
    if player == null:
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var base_move_speed: float = maxf(0.1, float(player.get("move_speed")))
    var sprint_multiplier: float = maxf(1.0, float(player.get("sprint_multiplier")))
    var max_run_speed: float = base_move_speed * sprint_multiplier
    var movement_ratio: float = clampf(horizontal_speed / max_run_speed, 0.0, 1.0)
    var sprinting: bool = bool(player.get("is_sprinting"))
    var airborne: bool = not player.is_on_floor()

    var motion_multiplier: float = 1.0 + movement_ratio * 0.70
    if sprinting:
        motion_multiplier += bow_sprint_sway_bonus
    if airborne:
        var vertical_ratio: float = clampf(absf(player.velocity.y) / 5.0, 0.0, 1.0)
        motion_multiplier += bow_airborne_sway_bonus + vertical_ratio * 0.35

    var overdraw_seconds: float = maxf(0.0, bow_draw_elapsed - bow_full_draw_seconds)
    var draw_amplitude_degrees: float = lerpf(
        bow_idle_camera_sway_degrees,
        bow_full_draw_camera_sway_degrees,
        bow_draw_power
    )
    draw_amplitude_degrees += minf(0.32, overdraw_seconds * 0.12)
    var amplitude_degrees: float = draw_amplitude_degrees * motion_multiplier

    var phase: float = bow_sway_phase
    var pitch_degrees: float = sin(phase * 1.85) * amplitude_degrees * 0.58
    var yaw_degrees: float = cos(phase * 2.27 + 0.72) * amplitude_degrees * 0.72
    var roll_degrees: float = sin(phase * 1.31 + 1.10) * amplitude_degrees * 0.34

    # Running adds a stronger rhythmic body/head sway. Airborne movement adds a
    # less predictable vertical component so drawing during jumps feels unstable.
    if horizontal_speed > 0.25:
        var stride_strength: float = movement_ratio * (1.35 if sprinting else 0.72)
        pitch_degrees += sin(phase * 6.4) * stride_strength * 0.22
        roll_degrees += cos(phase * 6.4) * stride_strength * 0.18
    if airborne:
        pitch_degrees += sin(phase * 3.9 + 0.4) * 0.30
        yaw_degrees += cos(phase * 3.2) * 0.24

    bow_applied_camera_rotation = Vector3(
        deg_to_rad(pitch_degrees),
        deg_to_rad(yaw_degrees),
        deg_to_rad(roll_degrees)
    )

    var position_amplitude: float = bow_camera_position_sway_meters * (0.45 + bow_draw_power * 0.55) * motion_multiplier
    bow_applied_camera_position = Vector3(
        sin(phase * 2.15) * position_amplitude,
        cos(phase * 1.72 + 0.35) * position_amplitude * (0.70 if not airborne else 1.05),
        0.0
    )

    bow_draw_camera.rotation += bow_applied_camera_rotation
    bow_draw_camera.position += bow_applied_camera_position

func _remove_camera_draw_sway() -> void:
    if bow_draw_camera != null and is_instance_valid(bow_draw_camera):
        bow_draw_camera.rotation -= bow_applied_camera_rotation
        bow_draw_camera.position -= bow_applied_camera_position
    bow_applied_camera_rotation = Vector3.ZERO
    bow_applied_camera_position = Vector3.ZERO
