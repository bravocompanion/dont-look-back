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

var tracked_player_id: int = 0
var player: CharacterBody3D
var panic_value: float = 0.0
var desktop_look_pixels: Vector2 = Vector2.ZERO
var current_move_speed: float = 0.0
var current_look_speed_deg: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # PanicTenantSystem runs at -20. Run immediately after it, but before the
    # Player consumes MobileControls.look_delta and before the network bridge.
    process_priority = -10
    _disable_legacy_panic_calculation()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        if _mobile_active() or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            return
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        desktop_look_pixels += motion.relative

func _process(delta: float) -> void:
    _disable_legacy_panic_calculation()

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _release_player()
        desktop_look_pixels = Vector2.ZERO
        return

    if not _ensure_player():
        desktop_look_pixels = Vector2.ZERO
        return

    if not _gameplay_allowed():
        desktop_look_pixels = Vector2.ZERO
        current_move_speed = 0.0
        current_look_speed_deg = 0.0
        _publish_panic()
        return

    current_move_speed = Vector2(player.velocity.x, player.velocity.z).length()
    current_look_speed_deg = _consume_real_look_speed(delta)
    _update_panic(delta)
    _publish_panic()

func get_panic() -> float:
    return panic_value

func get_movement_speed() -> float:
    return current_move_speed

func get_look_speed_degrees() -> float:
    return current_look_speed_deg

func _ensure_player() -> bool:
    var found: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if found == null:
        _release_player()
        return false

    var found_id: int = int(found.get_instance_id())
    if found_id == tracked_player_id and player == found:
        return true

    tracked_player_id = found_id
    player = found
    panic_value = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)
    desktop_look_pixels = Vector2.ZERO
    current_move_speed = 0.0
    current_look_speed_deg = 0.0
    _publish_panic()
    return true

func _release_player() -> void:
    tracked_player_id = 0
    player = null
    current_move_speed = 0.0
    current_look_speed_deg = 0.0

func _consume_real_look_speed(delta: float) -> float:
    if player == null or delta <= 0.0001:
        desktop_look_pixels = Vector2.ZERO
        return 0.0

    var angular_radians: float = 0.0
    if _mobile_active():
        var mobile: Node = get_node_or_null("/root/MobileControls")
        if mobile != null:
            var look_value: Variant = mobile.get("look_delta")
            if look_value is Vector2:
                var touch_delta: Vector2 = look_value
                var touch_sensitivity: float = float(player.get("touch_look_sensitivity"))
                angular_radians = touch_delta.length() * touch_sensitivity
        desktop_look_pixels = Vector2.ZERO
    else:
        var mouse_sensitivity: float = float(player.get("mouse_sensitivity"))
        angular_radians = desktop_look_pixels.length() * mouse_sensitivity
        desktop_look_pixels = Vector2.ZERO

    return rad_to_deg(angular_radians / delta)

func _update_panic(delta: float) -> void:
    var move_denominator: float = maxf(0.05, movement_full_panic_speed - movement_panic_threshold)
    var movement_factor: float = clampf((current_move_speed - movement_panic_threshold) / move_denominator, 0.0, 1.0)

    var look_denominator: float = maxf(1.0, look_full_panic_speed_deg - look_panic_threshold_deg)
    var look_factor: float = clampf((current_look_speed_deg - look_panic_threshold_deg) / look_denominator, 0.0, 1.0)

    var panic_gain: float = movement_factor * movement_panic_gain_per_second
    panic_gain += look_factor * look_panic_gain_per_second
    panic_gain = minf(maximum_combined_gain_per_second, panic_gain)

    if panic_gain > 0.001:
        panic_value = minf(100.0, panic_value + panic_gain * delta)
    else:
        panic_value = maxf(0.0, panic_value - calm_panic_decay_per_second * delta)

func _publish_panic() -> void:
    if player == null:
        return

    if player.has_method("set_flashlight_panic"):
        player.call("set_flashlight_panic", panic_value)
    else:
        player.set("flashlight_panic", panic_value)

    var legacy: Node = get_node_or_null("/root/PanicTenantSystem")
    if legacy != null:
        legacy.set("panic_value", panic_value)
        legacy.set("current_move_speed", current_move_speed)
        legacy.set("current_look_speed_deg", current_look_speed_deg)

    var panic_label: Label = player.get_node_or_null("HUD/PanicLabel") as Label
    if panic_label != null:
        var language: Node = get_node_or_null("/root/LanguageSystem")
        var indonesian: bool = language != null and language.has_method("is_indonesian") and bool(language.call("is_indonesian"))
        panic_label.text = "%s %d%%" % ["PANIK" if indonesian else "PANIC", int(round(panic_value))]

    var overlay: ColorRect = player.get_node_or_null("HUD/PanicOverlay") as ColorRect
    if overlay != null:
        var alpha: float = lerpf(0.0, 0.23, panic_value / 100.0)
        overlay.color = Color(0.18, 0.0, 0.0, alpha)

func _disable_legacy_panic_calculation() -> void:
    var legacy: Node = get_node_or_null("/root/PanicTenantSystem")
    if legacy == null:
        return
    legacy.set("movement_panic_gain_per_second", 0.0)
    legacy.set("look_panic_gain_per_second", 0.0)
    legacy.set("maximum_combined_gain_per_second", 0.0)
    legacy.set("calm_panic_decay_per_second", 0.0)

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

func _mobile_active() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
