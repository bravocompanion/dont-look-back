extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@export var movement_panic_threshold: float = 4.75
@export var movement_full_panic_speed: float = 6.75
@export var look_panic_threshold_deg: float = 95.0
@export var look_full_panic_speed_deg: float = 420.0
@export var movement_panic_gain_per_second: float = 16.0
@export var look_panic_gain_per_second: float = 20.0
@export var maximum_combined_gain_per_second: float = 32.0
@export var calm_panic_decay_per_second: float = 6.0
@export var idle_spawn_seconds: float = 2.0
@export var idle_move_speed: float = 0.12
@export var idle_look_speed_deg: float = 3.0
@export var spawn_request_cooldown: float = 2.5
@export var tenant_flashlight_dismiss_seconds: float = 3.0

var tracked_player_id: int = 0
var player: CharacterBody3D
var camera: Camera3D
var last_yaw: float = 0.0
var last_pitch: float = 0.0
var view_initialized: bool = false
var panic_value: float = 0.0
var idle_timer: float = 0.0
var request_cooldown: float = 0.0
var current_move_speed: float = 0.0
var current_look_speed_deg: float = 0.0
var tenant_flashlight_hold: float = 0.0
var tenant_flashlight_contact: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -20

func _process(delta: float) -> void:
    request_cooldown = maxf(0.0, request_cooldown - delta)

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _release_player()
        return

    if not _ensure_player():
        return

    if not _gameplay_allowed():
        idle_timer = 0.0
        tenant_flashlight_hold = 0.0
        tenant_flashlight_contact = false
        _update_hud()
        return

    _sample_motion(delta)
    _update_panic(delta)
    _update_idle_tenant(delta)
    _update_tenant_flashlight_dismissal(delta)
    _update_hud()

func get_panic() -> float:
    return panic_value

func get_idle_time() -> float:
    return idle_timer

func get_movement_speed() -> float:
    return current_move_speed

func get_look_speed_degrees() -> float:
    return current_look_speed_deg

func is_tenant_in_flashlight() -> bool:
    return tenant_flashlight_contact

func get_tenant_flashlight_hold() -> float:
    return tenant_flashlight_hold

func _ensure_player() -> bool:
    var found: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if found == null:
        _release_player()
        return false

    var found_camera: Camera3D = found.get_node_or_null("Camera3D") as Camera3D
    if found_camera == null:
        _release_player()
        return false

    var found_id: int = int(found.get_instance_id())
    if found_id == tracked_player_id and player == found and camera == found_camera:
        return true

    tracked_player_id = found_id
    player = found
    camera = found_camera
    panic_value = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)
    idle_timer = 0.0
    request_cooldown = 1.25
    tenant_flashlight_hold = 0.0
    tenant_flashlight_contact = false
    last_yaw = player.rotation.y
    last_pitch = camera.rotation.x
    view_initialized = true
    current_move_speed = 0.0
    current_look_speed_deg = 0.0
    _apply_panic_to_player()
    return true

func _release_player() -> void:
    tracked_player_id = 0
    player = null
    camera = null
    idle_timer = 0.0
    tenant_flashlight_hold = 0.0
    tenant_flashlight_contact = false
    view_initialized = false
    current_move_speed = 0.0
    current_look_speed_deg = 0.0

func _sample_motion(delta: float) -> void:
    if player == null or camera == null:
        return

    current_move_speed = Vector2(player.velocity.x, player.velocity.z).length()
    if delta <= 0.0001:
        current_look_speed_deg = 0.0
        return

    var yaw: float = player.rotation.y
    var pitch: float = camera.rotation.x
    if not view_initialized:
        last_yaw = yaw
        last_pitch = pitch
        current_look_speed_deg = 0.0
        view_initialized = true
        return

    var yaw_delta: float = absf(wrapf(yaw - last_yaw, -PI, PI))
    var pitch_delta: float = absf(wrapf(pitch - last_pitch, -PI, PI))
    last_yaw = yaw
    last_pitch = pitch
    var angular_delta: float = sqrt(yaw_delta * yaw_delta + pitch_delta * pitch_delta)
    current_look_speed_deg = rad_to_deg(angular_delta / delta)

func _update_panic(delta: float) -> void:
    var move_denominator: float = maxf(0.05, movement_full_panic_speed - movement_panic_threshold)
    var movement_factor: float = clampf((current_move_speed - movement_panic_threshold) / move_denominator, 0.0, 1.0)
    var look_denominator: float = maxf(1.0, look_full_panic_speed_deg - look_panic_threshold_deg)
    var look_factor: float = clampf((current_look_speed_deg - look_panic_threshold_deg) / look_denominator, 0.0, 1.0)

    var panic_gain: float = movement_factor * movement_panic_gain_per_second + look_factor * look_panic_gain_per_second
    panic_gain = minf(maximum_combined_gain_per_second, panic_gain)
    if panic_gain > 0.001:
        panic_value = minf(100.0, panic_value + panic_gain * delta)
    else:
        panic_value = maxf(0.0, panic_value - calm_panic_decay_per_second * delta)
    _apply_panic_to_player()

func _update_idle_tenant(delta: float) -> void:
    var stationary: bool = current_move_speed <= idle_move_speed and current_look_speed_deg <= idle_look_speed_deg
    if stationary:
        idle_timer = minf(idle_spawn_seconds, idle_timer + delta)
    else:
        idle_timer = 0.0
        return

    if idle_timer < idle_spawn_seconds or request_cooldown > 0.0 or _tenant_active():
        return

    var tenant: Node3D = _tenant_node()
    if tenant == null:
        idle_timer = 0.0
        request_cooldown = spawn_request_cooldown
        return

    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null and coop.has_method("request_tenant_encounter"):
            coop.call("request_tenant_encounter")
    elif tenant.has_method("appear_near_player"):
        tenant.call("appear_near_player")
    elif tenant.has_method("appear"):
        tenant.call("appear")

    idle_timer = 0.0
    request_cooldown = spawn_request_cooldown

func _update_tenant_flashlight_dismissal(delta: float) -> void:
    var tenant: Node3D = _tenant_node()
    if tenant == null or not tenant.visible or not bool(tenant.get("active")):
        tenant_flashlight_hold = 0.0
        tenant_flashlight_contact = false
        return

    tenant_flashlight_contact = _tenant_inside_flashlight_beam(tenant)
    if tenant_flashlight_contact:
        tenant_flashlight_hold = minf(tenant_flashlight_dismiss_seconds, tenant_flashlight_hold + delta)
    else:
        tenant_flashlight_hold = 0.0

    if _network_online() or tenant_flashlight_hold < tenant_flashlight_dismiss_seconds:
        return

    if tenant.has_method("stop_stalking"):
        tenant.call("stop_stalking")
    tenant_flashlight_hold = 0.0
    tenant_flashlight_contact = false
    idle_timer = 0.0
    request_cooldown = 0.35

func _tenant_inside_flashlight_beam(tenant: Node3D) -> bool:
    if player == null:
        return false
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight == null or not flashlight.visible or float(player.get("flashlight_battery")) <= 0.0:
        return false

    var origin: Vector3 = flashlight.global_position
    var focus: Vector3 = tenant.global_position + Vector3(0.0, 1.35, 0.0)
    var to_tenant: Vector3 = focus - origin
    var distance: float = to_tenant.length()
    if distance <= 0.05 or distance > flashlight.spot_range + 0.65:
        return false

    var forward: Vector3 = -flashlight.global_transform.basis.z.normalized()
    var direction: Vector3 = to_tenant / distance
    var half_angle: float = clampf(flashlight.spot_angle * 0.64, 10.0, 22.0)
    if forward.dot(direction) < cos(deg_to_rad(half_angle)):
        return false

    var world: World3D = player.get_world_3d()
    if world == null:
        return true
    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, focus)
    var excludes: Array[RID] = [player.get_rid()]
    query.exclude = excludes
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var hit: Dictionary = world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return true
    var hit_position_value: Variant = hit.get("position", null)
    if not (hit_position_value is Vector3):
        return false
    var hit_position: Vector3 = hit_position_value
    return origin.distance_to(hit_position) >= distance - 0.40

func _apply_panic_to_player() -> void:
    if player == null:
        return
    if player.has_method("set_flashlight_panic"):
        player.call("set_flashlight_panic", panic_value)
    else:
        player.set("flashlight_panic", panic_value)

func _update_hud() -> void:
    if player == null:
        return
    var panic_label: Label = player.get_node_or_null("HUD/PanicLabel") as Label
    if panic_label != null:
        var language: Node = get_node_or_null("/root/LanguageSystem")
        var prefix: String = "PANIK" if language != null and language.has_method("is_indonesian") and bool(language.call("is_indonesian")) else "PANIC"
        panic_label.text = "%s %d%%" % [prefix, int(round(panic_value))]
    var overlay: ColorRect = player.get_node_or_null("HUD/PanicOverlay") as ColorRect
    if overlay != null:
        var alpha: float = lerpf(0.0, 0.23, panic_value / 100.0)
        overlay.color = Color(0.18, 0.0, 0.0, alpha)

func _tenant_node() -> Node3D:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("Monster") as Node3D

func _tenant_active() -> bool:
    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null:
            return bool(coop.get("tenant_active"))
    var tenant: Node3D = _tenant_node()
    return tenant != null and tenant.visible and bool(tenant.get("active"))

func _gameplay_allowed() -> bool:
    if player == null or bool(player.get("is_dead")) or get_tree().paused:
        return false
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end != null and bool(front_end.get("menu_open")):
        return false
    var transition: Node = get_node_or_null("/root/MapTransitionSystem")
    if transition != null and bool(transition.get("transitioning")):
        return false
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return false
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null and bool(coop.get("local_downed")):
        return false
    return true

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
