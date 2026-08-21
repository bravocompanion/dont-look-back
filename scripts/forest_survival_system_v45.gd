extends "res://scripts/forest_survival_system_v44.gd"

const WILDLIFE_V45_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v45.gd"

@export var bow_full_draw_seconds: float = 1.35
@export var bow_min_release_power: float = 0.08
@export var bow_min_projectile_speed: float = 18.0
@export var bow_max_projectile_speed: float = 64.0
@export var bow_min_effective_range: float = 8.0
@export var bow_max_effective_range: float = 52.0
@export var bow_min_damage: float = 10.0
@export var bow_max_damage: float = 72.0
@export var bow_draw_fov_reduction: float = 3.0

var bow_drawing: bool = false
var bow_draw_elapsed: float = 0.0
var bow_draw_power: float = 0.0
var bow_sway_phase: float = 0.0
var bow_draw_camera: Camera3D
var bow_base_fov: float = 75.0
var arrow_shot_stats: Dictionary = {}

var draw_power_bar: ProgressBar
var draw_power_label: Label
var draw_aim_marker: Label

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V45_SCRIPT_PATH) as Script

func _process(delta: float) -> void:
    super._process(delta)
    _update_bow_draw(delta)
    _cleanup_v45_shot_stats()

func _unhandled_input(event: InputEvent) -> void:
    if not forest_active:
        if bow_drawing:
            _cancel_bow_draw()
        return
    if _ui_blocked():
        if bow_drawing:
            _cancel_bow_draw()
        return
    if event is InputEventMouseButton:
        var mouse_event: InputEventMouseButton = event as InputEventMouseButton
        if mouse_event.button_index != MOUSE_BUTTON_LEFT or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            return
        if mouse_event.pressed:
            _begin_bow_draw()
        else:
            _release_bow_draw()
        get_viewport().set_input_as_handled()

func _build_ui() -> void:
    super._build_ui()
    if hunt_button != null:
        if hunt_button.pressed.is_connected(_try_hunt):
            hunt_button.pressed.disconnect(_try_hunt)
        if not hunt_button.button_down.is_connected(_begin_bow_draw):
            hunt_button.button_down.connect(_begin_bow_draw)
        if not hunt_button.button_up.is_connected(_release_bow_draw):
            hunt_button.button_up.connect(_release_bow_draw)
        hunt_button.text = "HOLD HUNT"

    draw_power_bar = ProgressBar.new()
    draw_power_bar.name = "BowDrawPower"
    draw_power_bar.min_value = 0.0
    draw_power_bar.max_value = 100.0
    draw_power_bar.value = 0.0
    draw_power_bar.show_percentage = false
    draw_power_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    draw_power_bar.anchor_left = 0.5
    draw_power_bar.anchor_top = 0.5
    draw_power_bar.anchor_right = 0.5
    draw_power_bar.anchor_bottom = 0.5
    draw_power_bar.offset_left = -92.0
    draw_power_bar.offset_top = 58.0
    draw_power_bar.offset_right = 92.0
    draw_power_bar.offset_bottom = 70.0
    draw_power_bar.visible = false
    ui_layer.add_child(draw_power_bar)

    draw_power_label = Label.new()
    draw_power_label.name = "BowDrawLabel"
    draw_power_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    draw_power_label.anchor_left = 0.5
    draw_power_label.anchor_top = 0.5
    draw_power_label.anchor_right = 0.5
    draw_power_label.anchor_bottom = 0.5
    draw_power_label.offset_left = -140.0
    draw_power_label.offset_top = 74.0
    draw_power_label.offset_right = 140.0
    draw_power_label.offset_bottom = 98.0
    draw_power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    draw_power_label.add_theme_font_size_override("font_size", 13)
    draw_power_label.visible = false
    ui_layer.add_child(draw_power_label)

    draw_aim_marker = Label.new()
    draw_aim_marker.name = "BowSwayMarker"
    draw_aim_marker.text = "+"
    draw_aim_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
    draw_aim_marker.anchor_left = 0.5
    draw_aim_marker.anchor_top = 0.5
    draw_aim_marker.anchor_right = 0.5
    draw_aim_marker.anchor_bottom = 0.5
    draw_aim_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    draw_aim_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    draw_aim_marker.add_theme_font_size_override("font_size", 18)
    draw_aim_marker.visible = false
    ui_layer.add_child(draw_aim_marker)

func _update_ui(player: CharacterBody3D) -> void:
    super._update_ui(player)
    if hunt_button != null:
        hunt_button.text = "RELEASE %d%%" % int(round(bow_draw_power * 100.0)) if bow_drawing else "HOLD HUNT"

func _begin_bow_draw() -> void:
    if bow_drawing or not forest_active or bow_cooldown > 0.0 or _ui_blocked():
        return
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "hunting_bow")):
        _objective(player, "You need the Hunting Bow before drawing an arrow.")
        return
    if not bool(player.call("has_item", "arrow")):
        _objective(player, "No arrows left. Recover intact arrows or craft/find more.")
        return
    if float(player.get("stamina")) <= 1.0:
        _objective(player, "You are too exhausted to draw the bow steadily.")
        return

    bow_draw_camera = player.get_node_or_null("Camera3D") as Camera3D
    if bow_draw_camera == null:
        return
    bow_drawing = true
    bow_draw_elapsed = 0.0
    bow_draw_power = 0.0
    bow_sway_phase = 0.0
    bow_base_fov = bow_draw_camera.fov
    _set_draw_ui_visible(true)

func _release_bow_draw() -> void:
    if not bow_drawing:
        return
    var player: CharacterBody3D = _local_player()
    var camera: Camera3D = bow_draw_camera
    var release_power: float = clampf(maxf(bow_min_release_power, bow_draw_elapsed / maxf(0.1, bow_full_draw_seconds)), bow_min_release_power, 1.0)

    if player == null or camera == null or not is_instance_valid(camera):
        _cancel_bow_draw()
        return
    if not player.has_method("remove_item") or not bool(player.call("remove_item", "arrow")):
        _cancel_bow_draw()
        return

    var launch_direction: Vector3 = _current_swayed_direction(camera, release_power)
    var launch_origin: Vector3 = camera.global_position + launch_direction * 0.82
    var stamina_cost: float = lerpf(1.5, 5.5, release_power)
    player.set("stamina", maxf(0.0, float(player.get("stamina")) - stamina_cost))
    bow_cooldown = bow_cooldown_seconds

    _finish_bow_draw_visuals()

    if _network_online() and not _is_authoritative():
        _request_drawn_arrow_shot_remote.rpc_id(1, launch_origin, launch_direction, release_power)
    else:
        _host_spawn_drawn_arrow(_local_peer_id(), launch_origin, launch_direction, release_power)

func _cancel_bow_draw() -> void:
    if not bow_drawing:
        return
    _finish_bow_draw_visuals()

func _finish_bow_draw_visuals() -> void:
    bow_drawing = false
    bow_draw_elapsed = 0.0
    bow_draw_power = 0.0
    if bow_draw_camera != null and is_instance_valid(bow_draw_camera):
        bow_draw_camera.fov = bow_base_fov
    bow_draw_camera = null
    _set_draw_ui_visible(false)

func _update_bow_draw(delta: float) -> void:
    if not bow_drawing:
        return
    var player: CharacterBody3D = _local_player()
    if player == null or bool(player.get("is_dead")) or _ui_blocked():
        _cancel_bow_draw()
        return
    if not player.has_method("has_item") or not bool(player.call("has_item", "hunting_bow")) or not bool(player.call("has_item", "arrow")):
        _cancel_bow_draw()
        return

    bow_draw_elapsed += delta
    bow_sway_phase += delta
    bow_draw_power = clampf(bow_draw_elapsed / maxf(0.1, bow_full_draw_seconds), 0.0, 1.0)

    if bow_draw_camera != null and is_instance_valid(bow_draw_camera):
        var target_fov: float = bow_base_fov - bow_draw_fov_reduction * bow_draw_power
        bow_draw_camera.fov = lerpf(bow_draw_camera.fov, target_fov, clampf(delta * 9.0, 0.0, 1.0))

    if draw_power_bar != null:
        draw_power_bar.value = bow_draw_power * 100.0
    if draw_power_label != null:
        var damage_preview: int = int(round(_damage_for_power(maxf(bow_min_release_power, bow_draw_power))))
        var range_preview: int = int(round(_range_for_power(maxf(bow_min_release_power, bow_draw_power))))
        draw_power_label.text = "DRAW %d%%  •  DMG %d  •  RANGE %dm" % [int(round(bow_draw_power * 100.0)), damage_preview, range_preview]
    _update_sway_marker()

func _current_swayed_direction(camera: Camera3D, power: float) -> Vector3:
    var forward: Vector3 = -camera.global_transform.basis.z.normalized()
    var right: Vector3 = camera.global_transform.basis.x.normalized()
    var up: Vector3 = camera.global_transform.basis.y.normalized()
    var offsets: Vector2 = _sway_offsets_degrees(power)
    var horizontal: float = tan(deg_to_rad(offsets.x))
    var vertical: float = tan(deg_to_rad(offsets.y))
    return (forward + right * horizontal + up * vertical).normalized()

func _sway_offsets_degrees(power: float) -> Vector2:
    var overdraw_seconds: float = maxf(0.0, bow_draw_elapsed - bow_full_draw_seconds)
    var amplitude: float = 0.14 + 0.48 * power + minf(0.70, overdraw_seconds * 0.24)
    var horizontal: float = sin(bow_sway_phase * 2.15) * amplitude
    var vertical: float = cos(bow_sway_phase * 1.67 + 0.72) * amplitude * 0.72
    return Vector2(horizontal, vertical)

func _update_sway_marker() -> void:
    if draw_aim_marker == null:
        return
    var offsets: Vector2 = _sway_offsets_degrees(bow_draw_power)
    var pixel_scale: float = 14.0
    draw_aim_marker.offset_left = -12.0 + offsets.x * pixel_scale
    draw_aim_marker.offset_right = 12.0 + offsets.x * pixel_scale
    draw_aim_marker.offset_top = -12.0 - offsets.y * pixel_scale
    draw_aim_marker.offset_bottom = 12.0 - offsets.y * pixel_scale

func _set_draw_ui_visible(value: bool) -> void:
    if draw_power_bar != null:
        draw_power_bar.visible = value
    if draw_power_label != null:
        draw_power_label.visible = value
    if draw_aim_marker != null:
        draw_aim_marker.visible = value

func _speed_for_power(power: float) -> float:
    return lerpf(bow_min_projectile_speed, bow_max_projectile_speed, pow(clampf(power, 0.0, 1.0), 0.82))

func _range_for_power(power: float) -> float:
    return lerpf(bow_min_effective_range, bow_max_effective_range, pow(clampf(power, 0.0, 1.0), 1.05))

func _damage_for_power(power: float) -> float:
    return lerpf(bow_min_damage, bow_max_damage, pow(clampf(power, 0.0, 1.0), 1.35))

@rpc("any_peer", "call_remote", "reliable", 36)
func _request_drawn_arrow_shot_remote(launch_origin: Vector3, launch_direction: Vector3, requested_power: float) -> void:
    if not _is_authoritative():
        return
    var sender_peer_id: int = multiplayer.get_remote_sender_id()
    if sender_peer_id <= 0 or launch_direction.length_squared() <= 0.25:
        return
    var sender_player: CharacterBody3D = _player_for_peer(sender_peer_id)
    if sender_player != null and sender_player.global_position.distance_to(launch_origin) > 4.0:
        return
    _host_spawn_drawn_arrow(sender_peer_id, launch_origin, launch_direction.normalized(), clampf(requested_power, bow_min_release_power, 1.0))

func _host_spawn_drawn_arrow(shooter_peer_id: int, launch_origin: Vector3, launch_direction: Vector3, power: float) -> void:
    if not _is_authoritative() or not forest_active:
        return
    var safe_power: float = clampf(power, bow_min_release_power, 1.0)
    var projectile_speed: float = _speed_for_power(safe_power)
    var effective_range: float = _range_for_power(safe_power)
    var base_damage: float = _damage_for_power(safe_power)

    var projectile_id: int = next_arrow_projectile_id
    next_arrow_projectile_id += 1
    if next_arrow_projectile_id >= 2000000000:
        next_arrow_projectile_id = 1

    arrow_shot_stats[projectile_id] = {
        "power": safe_power,
        "speed": projectile_speed,
        "range": effective_range,
        "damage": base_damage
    }

    if _network_online():
        _spawn_drawn_arrow_projectile_remote.rpc(projectile_id, shooter_peer_id, launch_origin, launch_direction.normalized(), projectile_speed, effective_range)
    else:
        _spawn_drawn_arrow_projectile_remote(projectile_id, shooter_peer_id, launch_origin, launch_direction.normalized(), projectile_speed, effective_range)

@rpc("authority", "call_local", "reliable", 37)
func _spawn_drawn_arrow_projectile_remote(projectile_id: int, shooter_peer_id: int, launch_origin: Vector3, launch_direction: Vector3, projectile_speed: float, effective_range: float) -> void:
    if arrow_projectiles.has(projectile_id):
        return
    if arrow_projectile_script == null:
        arrow_projectile_script = load(ARROW_PROJECTILE_SCRIPT_PATH) as Script
    if arrow_projectile_script == null:
        return

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return
    var root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if root == null:
        return

    var projectile: StaticBody3D = StaticBody3D.new()
    projectile.name = "ArrowProjectile_%d" % projectile_id
    projectile.set_script(arrow_projectile_script)
    root.add_child(projectile)
    if projectile.has_method("configure"):
        projectile.call(
            "configure",
            projectile_id,
            shooter_peer_id,
            launch_origin,
            launch_direction,
            projectile_speed,
            effective_range,
            arrow_projectile_gravity,
            arrow_projectile_lifetime,
            _is_authoritative()
        )
    arrow_projectiles[projectile_id] = projectile

func on_arrow_projectile_hit(
    projectile_id: int,
    collider_value: Variant,
    impact_position: Vector3,
    impact_normal: Vector3,
    shooter_peer_id: int,
    within_damage_range: bool
) -> void:
    if not _is_authoritative():
        return

    var stats: Dictionary = Dictionary(arrow_shot_stats.get(projectile_id, {}))
    var power: float = float(stats.get("power", bow_min_release_power))
    var effective_range: float = maxf(1.0, float(stats.get("range", _range_for_power(power))))
    var base_damage: float = float(stats.get("damage", _damage_for_power(power)))
    var projectile: Node = arrow_projectiles.get(projectile_id, null) as Node
    var travelled: float = float(projectile.get("travelled_distance")) if projectile != null else effective_range
    var distance_ratio: float = clampf(travelled / effective_range, 0.0, 1.0)
    var impact_damage: float = base_damage * lerpf(1.0, 0.68, distance_ratio)
    arrow_shot_stats.erase(projectile_id)

    var can_recover: bool = weather_rng.randf() >= ARROW_BREAK_CHANCE
    var recovery_note: String = " Arrow intact — recover it from the impact point." if can_recover else " Arrow broke on impact."
    var animal: Node = _wildlife_from_collider(collider_value)
    var animal_killed: bool = false

    if animal != null and within_damage_range and bool(animal.get("alive")) and animal.has_method("take_hunting_damage"):
        pending_arrow_recovery_note_by_peer[shooter_peer_id] = recovery_note
        animal.call("take_hunting_damage", impact_damage, shooter_peer_id)
        animal_killed = not bool(animal.get("alive"))
        if not animal_killed:
            pending_arrow_recovery_note_by_peer.erase(shooter_peer_id)
    elif animal != null and not within_damage_range:
        _message_peer(shooter_peer_id, "The arrow reached the animal beyond this draw's effective range.%s" % recovery_note)

    _broadcast_arrow_impact(projectile_id, impact_position, impact_normal, can_recover)

    if animal_killed:
        return
    if animal != null and within_damage_range:
        var remaining_hp: float = maxf(0.0, float(animal.get("current_health")))
        var max_hp: float = maxf(1.0, float(animal.get("max_health")))
        _message_peer(
            shooter_peer_id,
            "HIT: %s — %d / %d HP. Damage %d, draw %d%%.%s" % [
                str(animal.get("animal_kind")).capitalize(),
                int(ceil(remaining_hp)),
                int(round(max_hp)),
                int(round(impact_damage)),
                int(round(power * 100.0)),
                recovery_note
            ]
        )
    elif animal == null:
        _message_peer(shooter_peer_id, "The arrow struck the environment at %d%% draw.%s" % [int(round(power * 100.0)), recovery_note])

func on_arrow_projectile_timeout(projectile_id: int, shooter_peer_id: int) -> void:
    arrow_shot_stats.erase(projectile_id)
    super.on_arrow_projectile_timeout(projectile_id, shooter_peer_id)

func _cleanup_v45_shot_stats() -> void:
    var stale_ids: Array = []
    for id_value: Variant in arrow_shot_stats.keys():
        if not arrow_projectiles.has(id_value):
            stale_ids.append(id_value)
    for id_value: Variant in stale_ids:
        arrow_shot_stats.erase(id_value)
