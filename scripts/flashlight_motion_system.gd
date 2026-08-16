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
@export var monster_interference_max_seconds: float = 3.0
@export var monster_interference_max_drain_multiplier: float = 2.0
@export var monster_contact_grace_seconds: float = 0.16

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

var monster_interference_active: bool = false
var monster_exposure_seconds: float = 0.0
var monster_interference_strength: float = 0.0
var monster_contact_grace: float = 0.0
var battery_drain_multiplier: float = 1.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 50

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
    _update_monster_interference(delta)

func is_monster_interference_active() -> bool:
    return monster_interference_active

func get_monster_interference_strength() -> float:
    return monster_interference_strength

func get_battery_drain_multiplier() -> float:
    return battery_drain_multiplier

func get_monster_exposure_seconds() -> float:
    return monster_exposure_seconds

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
    _reset_monster_interference()
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
    _reset_monster_interference()

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

func _update_monster_interference(delta: float) -> void:
    if player == null or flashlight == null:
        _reset_monster_interference()
        return

    var battery: float = float(player.get("flashlight_battery"))
    var can_interfere: bool = player.can_process() and flashlight.visible and battery > 0.0 and not bool(player.get("is_dead"))
    var touching_monster: bool = can_interfere and _flashlight_hits_any_monster()

    if touching_monster:
        monster_contact_grace = monster_contact_grace_seconds
        monster_exposure_seconds = minf(monster_interference_max_seconds, monster_exposure_seconds + delta)
    elif monster_contact_grace > 0.0 and can_interfere:
        monster_contact_grace = maxf(0.0, monster_contact_grace - delta)
    else:
        _reset_monster_interference()
        return

    monster_interference_active = true
    var safe_max_seconds: float = maxf(0.05, monster_interference_max_seconds)
    monster_interference_strength = clampf(monster_exposure_seconds / safe_max_seconds, 0.0, 1.0)
    battery_drain_multiplier = lerpf(1.0, maxf(1.0, monster_interference_max_drain_multiplier), monster_interference_strength)

    if touching_monster:
        var base_drain: float = maxf(0.0, float(player.get("flashlight_drain_per_second")))
        var extra_drain: float = base_drain * maxf(0.0, battery_drain_multiplier - 1.0) * delta
        var remaining_battery: float = maxf(0.0, float(player.get("flashlight_battery")) - extra_drain)
        player.set("flashlight_battery", remaining_battery)

    _apply_monster_interference_flicker()

func _apply_monster_interference_flicker() -> void:
    if flashlight == null or not flashlight.visible:
        return

    var strength: float = clampf(monster_interference_strength, 0.0, 1.0)
    var period_ms: float = lerpf(128.0, 54.0, strength)
    var phase: float = float(Time.get_ticks_msec()) / period_ms
    var flicker_floor: float = lerpf(0.70, 0.34, strength)
    var pulse: float = flicker_floor + (1.0 - flicker_floor) * absf(sin(phase))
    var effect_weight: float = lerpf(0.28, 0.92, strength)
    var energy_multiplier: float = lerpf(1.0, pulse, effect_weight)
    flashlight.light_energy *= energy_multiplier

func _flashlight_hits_any_monster() -> bool:
    if player == null or flashlight == null:
        return false

    var origin: Vector3 = flashlight.global_position
    var forward: Vector3 = -flashlight.global_transform.basis.z.normalized()
    var max_distance: float = flashlight.spot_range + 0.65
    var beam_half_angle: float = clampf(flashlight.spot_angle * 0.64, 10.0, 22.0)
    var minimum_dot: float = cos(deg_to_rad(beam_half_angle))

    for monster: Node3D in _monster_candidates():
        if monster == null or not is_instance_valid(monster) or not monster.visible:
            continue
        var focus: Vector3 = _monster_focus_position(monster)
        var to_monster: Vector3 = focus - origin
        var distance: float = to_monster.length()
        if distance <= 0.05 or distance > max_distance:
            continue
        var direction: Vector3 = to_monster / distance
        if forward.dot(direction) < minimum_dot:
            continue
        if _has_clear_beam_line(origin, focus, monster):
            return true
    return false

func _monster_candidates() -> Array[Node3D]:
    var result: Array[Node3D] = []
    var seen_ids: Dictionary = {}
    var groups: Array[StringName] = [StringName("arc1_enemy"), StringName("arc1_warden"), StringName("darkness_creature")]

    for group_name: StringName in groups:
        for candidate: Node in get_tree().get_nodes_in_group(group_name):
            if not (candidate is Node3D):
                continue
            var monster: Node3D = candidate as Node3D
            var instance_id: int = int(monster.get_instance_id())
            if seen_ids.has(instance_id):
                continue
            seen_ids[instance_id] = true
            result.append(monster)

    var scene: Node = get_tree().current_scene
    if scene != null:
        var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D
        if tenant != null and is_instance_valid(tenant):
            var tenant_id: int = int(tenant.get_instance_id())
            if not seen_ids.has(tenant_id):
                seen_ids[tenant_id] = true
                result.append(tenant)

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        var dark_value: Variant = coop.get("dark_node")
        if dark_value is Node3D:
            var shared_darkness: Node3D = dark_value
            if is_instance_valid(shared_darkness):
                var dark_id: int = int(shared_darkness.get_instance_id())
                if not seen_ids.has(dark_id):
                    result.append(shared_darkness)

    return result

func _monster_focus_position(monster: Node3D) -> Vector3:
    var height: float = 1.20
    if monster.is_in_group("arc1_warden"):
        height = 1.35
    elif monster.is_in_group("darkness_creature"):
        height = 1.25
    elif monster.is_in_group("arc1_enemy"):
        var enemy_kind: String = str(monster.get("enemy_kind"))
        height = 0.52 if enemy_kind == "crawler" else 1.30
    return monster.global_position + Vector3(0.0, height, 0.0)

func _has_clear_beam_line(origin: Vector3, target: Vector3, monster: Node3D) -> bool:
    if player == null:
        return true
    var world: World3D = player.get_world_3d()
    if world == null:
        return true

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, target)
    var excludes: Array[RID] = [player.get_rid()]
    query.exclude = excludes
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var hit: Dictionary = world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return true

    var collider_value: Variant = hit.get("collider", null)
    if collider_value is Node:
        var collider_node: Node = collider_value
        if _collider_belongs_to_monster(collider_node, monster):
            return true

    var hit_position_value: Variant = hit.get("position", null)
    if not (hit_position_value is Vector3):
        return false
    var hit_position: Vector3 = hit_position_value
    var target_distance: float = origin.distance_to(target)
    var hit_distance: float = origin.distance_to(hit_position)
    return hit_distance >= target_distance - 0.40

func _collider_belongs_to_monster(collider: Node, monster: Node3D) -> bool:
    var current: Node = collider
    while current != null:
        if current == monster:
            return true
        current = current.get_parent()
    return false

func _reset_monster_interference() -> void:
    monster_interference_active = false
    monster_exposure_seconds = 0.0
    monster_interference_strength = 0.0
    monster_contact_grace = 0.0
    battery_drain_multiplier = 1.0

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
