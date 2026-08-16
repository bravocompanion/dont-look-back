extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const FULL_BATTERY_ENERGY: float = 6.7

@export var mobile_motion_scale: float = 0.74
@export var idle_pitch_degrees: float = 0.42
@export var idle_yaw_degrees: float = 0.26
@export var walk_pitch_degrees: float = 1.15
@export var walk_yaw_degrees: float = 0.72
@export var sprint_pitch_degrees: float = 2.85
@export var sprint_yaw_degrees: float = 2.10
@export var max_look_lag_degrees: float = 4.6

var tracked_player_id: int = 0
var player: CharacterBody3D
var camera: Camera3D
var flashlight: SpotLight3D
var base_position: Vector3 = Vector3.ZERO
var base_rotation: Vector3 = Vector3.ZERO
var base_spot_range: float = 13.0
var base_spot_angle: float = 28.0

var breath_phase: float = 0.0
var bob_phase: float = 0.0
var look_lag: Vector3 = Vector3.ZERO
var smoothed_rotation_offset: Vector3 = Vector3.ZERO
var smoothed_position_offset: Vector3 = Vector3.ZERO
var landing_pitch: float = 0.0
var jump_pitch: float = 0.0
var previous_grounded: bool = true
var previous_vertical_velocity: float = 0.0
var last_view_yaw: float = 0.0
var last_view_pitch: float = 0.0
var view_initialized: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _release_player()
        return

    if not _ensure_player():
        return

    _update_jump_and_landing(delta)
    _update_look_inertia(delta)
    _update_flashlight_motion(delta)
    _update_flashlight_beam()

func _ensure_player() -> bool:
    var found: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if found == null:
        _release_player()
        return false

    var found_id: int = int(found.get_instance_id())
    if found_id == tracked_player_id and player != null and camera != null and flashlight != null:
        return true

    var found_camera: Camera3D = found.get_node_or_null("Camera3D") as Camera3D
    var found_flashlight: SpotLight3D = found.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if found_camera == null or found_flashlight == null:
        _release_player()
        return false

    tracked_player_id = found_id
    player = found
    camera = found_camera
    flashlight = found_flashlight
    base_position = flashlight.position
    base_rotation = flashlight.rotation
    base_spot_range = flashlight.spot_range
    base_spot_angle = flashlight.spot_angle
    player.set("flashlight_base_energy", FULL_BATTERY_ENERGY)
    if float(player.get("flashlight_battery")) > 0.0:
        flashlight.light_energy = FULL_BATTERY_ENERGY
    breath_phase = 0.0
    bob_phase = 0.0
    look_lag = Vector3.ZERO
    smoothed_rotation_offset = Vector3.ZERO
    smoothed_position_offset = Vector3.ZERO
    landing_pitch = 0.0
    jump_pitch = 0.0
    previous_grounded = player.is_on_floor()
    previous_vertical_velocity = player.velocity.y
    last_view_yaw = player.rotation.y
    last_view_pitch = camera.rotation.x
    view_initialized = true
    return true

func _release_player() -> void:
    if flashlight != null and is_instance_valid(flashlight):
        flashlight.position = base_position
        flashlight.rotation = base_rotation
        flashlight.spot_range = base_spot_range
        flashlight.spot_angle = base_spot_angle
    tracked_player_id = 0
    player = null
    camera = null
    flashlight = null
    view_initialized = false

func _update_flashlight_motion(delta: float) -> void:
    if player == null or flashlight == null:
        return

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var sprinting: bool = bool(player.get("is_sprinting")) and horizontal_speed > 0.35
    var walking: bool = horizontal_speed > 0.28 and not sprinting

    var stamina: float = float(player.get("stamina"))
    var max_stamina: float = maxf(1.0, float(player.get("max_stamina")))
    var health: float = float(player.get("health"))
    var max_health: float = maxf(1.0, float(player.get("max_health")))
    var panic: float = clampf(float(player.get("flashlight_panic")) / 100.0, 0.0, 1.0)
    var darkness: float = clampf(float(player.get("darkness_exposure")) / 100.0, 0.0, 1.0)

    var low_stamina: float = 1.0 - clampf(stamina / max_stamina, 0.0, 1.0)
    var low_health: float = 1.0 - clampf(health / max_health, 0.0, 1.0)
    var stress: float = clampf(low_stamina * 0.35 + low_health * 0.38 + panic * 0.42 + darkness * 0.16, 0.0, 0.82)
    var motion_scale: float = mobile_motion_scale if _mobile_active() else 1.0

    breath_phase += delta * (1.28 + stress * 0.62)
    var breath_pitch: float = sin(breath_phase) * deg_to_rad(idle_pitch_degrees)
    var breath_yaw: float = cos(breath_phase * 0.73) * deg_to_rad(idle_yaw_degrees)
    var breath_roll: float = sin(breath_phase * 0.51) * deg_to_rad(0.10)
    var breath_position: Vector3 = Vector3(
        cos(breath_phase * 0.76) * 0.0028,
        sin(breath_phase) * 0.0048,
        0.0
    )

    var movement_rotation: Vector3 = Vector3.ZERO
    var movement_position: Vector3 = Vector3.ZERO
    if sprinting:
        bob_phase += delta * (9.8 + minf(horizontal_speed, 8.0) * 0.24)
        movement_rotation.x = sin(bob_phase) * deg_to_rad(sprint_pitch_degrees)
        movement_rotation.y = sin(bob_phase * 0.52 + 0.8) * deg_to_rad(sprint_yaw_degrees)
        movement_rotation.z = cos(bob_phase * 0.52) * deg_to_rad(0.86)
        movement_position.x = sin(bob_phase * 0.52) * 0.018
        movement_position.y = absf(sin(bob_phase)) * -0.026
        movement_position.z = cos(bob_phase) * 0.010
    elif walking:
        bob_phase += delta * (6.6 + minf(horizontal_speed, 6.0) * 0.28)
        movement_rotation.x = sin(bob_phase) * deg_to_rad(walk_pitch_degrees)
        movement_rotation.y = sin(bob_phase * 0.51 + 0.7) * deg_to_rad(walk_yaw_degrees)
        movement_rotation.z = cos(bob_phase * 0.51) * deg_to_rad(0.32)
        movement_position.x = sin(bob_phase * 0.51) * 0.008
        movement_position.y = absf(sin(bob_phase)) * -0.012
        movement_position.z = cos(bob_phase) * 0.004
    else:
        bob_phase = fmod(bob_phase, TAU)

    var stress_rotation: Vector3 = Vector3(
        sin(breath_phase * 3.73 + 0.4),
        sin(breath_phase * 4.61 + 1.7),
        sin(breath_phase * 3.17 + 2.4)
    ) * deg_to_rad(0.58 * stress)

    var target_rotation: Vector3 = Vector3(breath_pitch, breath_yaw, breath_roll)
    target_rotation += movement_rotation
    target_rotation += stress_rotation
    target_rotation += look_lag
    target_rotation.x += landing_pitch + jump_pitch
    target_rotation *= motion_scale

    var target_position: Vector3 = (breath_position + movement_position) * motion_scale
    var smoothing: float = 13.0 if sprinting else 10.0 if walking else 7.2
    var blend: float = clampf(delta * smoothing, 0.0, 1.0)
    smoothed_rotation_offset = smoothed_rotation_offset.lerp(target_rotation, blend)
    smoothed_position_offset = smoothed_position_offset.lerp(target_position, blend)

    flashlight.rotation = base_rotation + smoothed_rotation_offset
    flashlight.position = base_position + smoothed_position_offset

func _update_look_inertia(delta: float) -> void:
    if player == null or camera == null:
        return
    var current_yaw: float = player.rotation.y
    var current_pitch: float = camera.rotation.x
    if not view_initialized:
        last_view_yaw = current_yaw
        last_view_pitch = current_pitch
        view_initialized = true
        return

    var yaw_delta: float = wrapf(current_yaw - last_view_yaw, -PI, PI)
    var pitch_delta: float = wrapf(current_pitch - last_view_pitch, -PI, PI)
    last_view_yaw = current_yaw
    last_view_pitch = current_pitch

    var max_lag: float = deg_to_rad(max_look_lag_degrees)
    look_lag.y = clampf(look_lag.y - yaw_delta * 0.38, -max_lag, max_lag)
    look_lag.x = clampf(look_lag.x - pitch_delta * 0.34, -max_lag * 0.82, max_lag * 0.82)
    look_lag.z = clampf(look_lag.z + yaw_delta * 0.08, -max_lag * 0.28, max_lag * 0.28)
    look_lag = look_lag.lerp(Vector3.ZERO, clampf(delta * 7.4, 0.0, 1.0))

func _update_jump_and_landing(delta: float) -> void:
    if player == null:
        return
    var grounded: bool = player.is_on_floor()
    var vertical_velocity: float = player.velocity.y

    if previous_grounded and not grounded and vertical_velocity > 0.6:
        jump_pitch = deg_to_rad(-1.25)
    elif not previous_grounded and grounded:
        var impact_speed: float = absf(previous_vertical_velocity)
        var landing_degrees: float = clampf(0.65 + impact_speed * 0.30, 0.65, 3.2)
        landing_pitch = deg_to_rad(landing_degrees)

    jump_pitch = move_toward(jump_pitch, 0.0, deg_to_rad(5.8) * delta)
    landing_pitch = move_toward(landing_pitch, 0.0, deg_to_rad(9.5) * delta)
    previous_grounded = grounded
    previous_vertical_velocity = vertical_velocity

func _update_flashlight_beam() -> void:
    if player == null or flashlight == null:
        return

    if not flashlight.visible:
        flashlight.spot_range = base_spot_range
        flashlight.spot_angle = base_spot_angle
        return

    var battery: float = float(player.get("flashlight_battery"))
    var max_battery: float = maxf(1.0, float(player.get("max_flashlight_battery")))
    var ratio: float = clampf(battery / max_battery, 0.0, 1.0)
    var range_factor: float = 1.0
    if ratio < 0.22:
        range_factor = lerpf(0.78, 0.94, ratio / 0.22)
    flashlight.spot_range = base_spot_range * range_factor

    var horizontal_speed: float = Vector2(player.velocity.x, player.velocity.z).length()
    var sprinting: bool = bool(player.get("is_sprinting")) and horizontal_speed > 0.35
    var angle_bonus: float = 1.35 if sprinting else 0.0
    flashlight.spot_angle = base_spot_angle + angle_bonus

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
