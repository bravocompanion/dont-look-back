extends Node

@export var joystick_deadzone: float = 0.12
@export var editor_preview_width: float = 820.0

var mobile_active: bool = false
var dead_mode: bool = false
var sprint_pressed: bool = false
var move_touch_id: int = -1
var look_touch_id: int = -1
var move_vector: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var queued_actions: Dictionary = {}
var layout_timer: float = 0.0

var layer: CanvasLayer
var root: Control
var joystick_base: Panel
var joystick_knob: Panel
var interact_button: Button
var sprint_button: Button
var flashlight_button: Button
var battery_button: Button
var food_button: Button
var water_button: Button
var medkit_button: Button
var restart_button: Button

func _ready() -> void:
    _build_ui()
    _refresh_mode_and_layout()

func _process(delta: float) -> void:
    layout_timer -= delta
    if layout_timer <= 0.0:
        layout_timer = 0.35
        _refresh_mode_and_layout()

func _input(event: InputEvent) -> void:
    if not mobile_active or root == null or not root.visible:
        return

    if event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event as InputEventScreenTouch
        if touch.pressed:
            if _is_over_action_button(touch.position):
                return
            if move_touch_id < 0 and joystick_base != null and joystick_base.get_global_rect().grow(32.0).has_point(touch.position):
                move_touch_id = touch.index
                _update_move_vector(touch.position)
                get_viewport().set_input_as_handled()
                return
            var viewport_size: Vector2 = get_viewport().get_visible_rect().size
            if look_touch_id < 0 and touch.position.x >= viewport_size.x * 0.34:
                look_touch_id = touch.index
                get_viewport().set_input_as_handled()
        else:
            if touch.index == move_touch_id:
                move_touch_id = -1
                move_vector = Vector2.ZERO
                _update_joystick_visual()
                get_viewport().set_input_as_handled()
            if touch.index == look_touch_id:
                look_touch_id = -1
                get_viewport().set_input_as_handled()

    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event as InputEventScreenDrag
        if drag.index == move_touch_id:
            _update_move_vector(drag.position)
            get_viewport().set_input_as_handled()
        elif drag.index == look_touch_id:
            look_delta += drag.relative
            get_viewport().set_input_as_handled()

func is_mobile_active() -> bool:
    return mobile_active

func get_move_vector() -> Vector2:
    return move_vector if mobile_active and not dead_mode else Vector2.ZERO

func consume_look_delta() -> Vector2:
    var result: Vector2 = look_delta
    look_delta = Vector2.ZERO
    if not mobile_active or dead_mode:
        return Vector2.ZERO
    return result

func is_sprint_pressed() -> bool:
    return mobile_active and not dead_mode and sprint_pressed

func consume_action(action: String) -> bool:
    var requested: bool = bool(queued_actions.get(action, false))
    if requested:
        queued_actions[action] = false
    return requested

func set_dead_mode(value: bool) -> void:
    dead_mode = value
    sprint_pressed = false
    move_touch_id = -1
    look_touch_id = -1
    move_vector = Vector2.ZERO
    look_delta = Vector2.ZERO
    _update_joystick_visual()
    _update_action_visibility()

func _queue_action(action: String) -> void:
    if dead_mode and action != "restart":
        return
    queued_actions[action] = true

func _set_sprint(value: bool) -> void:
    sprint_pressed = value and not dead_mode

func _update_move_vector(screen_position: Vector2) -> void:
    if joystick_base == null:
        return
    var center: Vector2 = joystick_base.get_global_rect().get_center()
    var radius: float = maxf(1.0, joystick_base.size.x * 0.5)
    var raw: Vector2 = (screen_position - center) / radius
    if raw.length() > 1.0:
        raw = raw.normalized()
    if raw.length() < joystick_deadzone:
        raw = Vector2.ZERO
    move_vector = raw
    _update_joystick_visual()

func _update_joystick_visual() -> void:
    if joystick_base == null or joystick_knob == null:
        return
    var base_center: Vector2 = joystick_base.position + joystick_base.size * 0.5
    var travel: float = joystick_base.size.x * 0.31
    joystick_knob.position = base_center - joystick_knob.size * 0.5 + move_vector * travel

func _refresh_mode_and_layout() -> void:
    if root == null:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var editor_preview: bool = OS.has_feature("editor") and viewport_size.x <= editor_preview_width
    mobile_active = OS.has_feature("mobile") or editor_preview
    root.visible = mobile_active
    if not mobile_active:
        move_vector = Vector2.ZERO
        look_delta = Vector2.ZERO
        sprint_pressed = false
        return
    _layout_ui(viewport_size)
    _update_action_visibility()

func _layout_ui(viewport_size: Vector2) -> void:
    var short_side: float = minf(viewport_size.x, viewport_size.y)
    var joystick_size: float = clampf(short_side * 0.235, 118.0, 170.0)
    var action_size: float = clampf(short_side * 0.115, 62.0, 86.0)
    var small_size: float = clampf(short_side * 0.082, 48.0, 62.0)
    var margin: float = clampf(short_side * 0.035, 16.0, 28.0)
    var gap: float = clampf(short_side * 0.018, 8.0, 14.0)

    joystick_base.position = Vector2(margin, viewport_size.y - margin - joystick_size)
    joystick_base.size = Vector2(joystick_size, joystick_size)
    joystick_knob.size = Vector2(joystick_size * 0.38, joystick_size * 0.38)
    _update_joystick_visual()

    interact_button.size = Vector2(action_size, action_size)
    interact_button.position = Vector2(viewport_size.x - margin - action_size, viewport_size.y - margin - action_size)

    sprint_button.size = Vector2(action_size, action_size)
    sprint_button.position = Vector2(viewport_size.x - margin - action_size * 2.0 - gap, viewport_size.y - margin - action_size * 0.78)

    flashlight_button.size = Vector2(action_size, action_size)
    flashlight_button.position = Vector2(viewport_size.x - margin - action_size, viewport_size.y - margin - action_size * 2.0 - gap)

    battery_button.size = Vector2(action_size, action_size)
    battery_button.position = Vector2(viewport_size.x - margin - action_size * 2.0 - gap, viewport_size.y - margin - action_size * 1.82 - gap)

    var item_y: float = viewport_size.y - margin - small_size
    var item_center_x: float = viewport_size.x * 0.52
    food_button.size = Vector2(small_size, small_size)
    water_button.size = Vector2(small_size, small_size)
    medkit_button.size = Vector2(small_size, small_size)
    food_button.position = Vector2(item_center_x - small_size * 1.6 - gap, item_y)
    water_button.position = Vector2(item_center_x - small_size * 0.5, item_y)
    medkit_button.position = Vector2(item_center_x + small_size * 0.6 + gap, item_y)

    restart_button.size = Vector2(clampf(short_side * 0.36, 180.0, 260.0), clampf(short_side * 0.10, 58.0, 76.0))
    restart_button.position = viewport_size * 0.5 - restart_button.size * 0.5 + Vector2(0.0, short_side * 0.18)

    var action_font: int = int(clampf(short_side * 0.030, 15.0, 21.0))
    var small_font: int = int(clampf(short_side * 0.022, 12.0, 16.0))
    for button: Button in [interact_button, sprint_button, flashlight_button, battery_button]:
        button.add_theme_font_size_override("font_size", action_font)
    for button: Button in [food_button, water_button, medkit_button]:
        button.add_theme_font_size_override("font_size", small_font)
    restart_button.add_theme_font_size_override("font_size", action_font)

func _update_action_visibility() -> void:
    if interact_button == null:
        return
    var gameplay_visible: bool = mobile_active and not dead_mode
    joystick_base.visible = gameplay_visible
    joystick_knob.visible = gameplay_visible
    interact_button.visible = gameplay_visible
    sprint_button.visible = gameplay_visible
    flashlight_button.visible = gameplay_visible
    battery_button.visible = gameplay_visible
    food_button.visible = gameplay_visible
    water_button.visible = gameplay_visible
    medkit_button.visible = gameplay_visible
    restart_button.visible = mobile_active and dead_mode

func _is_over_action_button(point: Vector2) -> bool:
    for button: Button in [interact_button, sprint_button, flashlight_button, battery_button, food_button, water_button, medkit_button, restart_button]:
        if button != null and button.visible and button.get_global_rect().has_point(point):
            return true
    return false

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "MobileControlsLayer"
    layer.layer = 18
    add_child(layer)

    root = Control.new()
    root.name = "MobileControlsRoot"
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(root)

    joystick_base = Panel.new()
    joystick_base.name = "MoveBase"
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_base.add_theme_stylebox_override("panel", _round_style(Color(0.08, 0.09, 0.10, 0.42), 999))
    root.add_child(joystick_base)

    joystick_knob = Panel.new()
    joystick_knob.name = "MoveKnob"
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    joystick_knob.add_theme_stylebox_override("panel", _round_style(Color(0.78, 0.80, 0.80, 0.56), 999))
    root.add_child(joystick_knob)

    interact_button = _make_button("USE", "interact")
    sprint_button = _make_hold_button("RUN")
    flashlight_button = _make_button("LIGHT", "flashlight")
    battery_button = _make_button("BATT", "battery")
    food_button = _make_button("FOOD", "food")
    water_button = _make_button("WATER", "water")
    medkit_button = _make_button("MED", "medkit")
    restart_button = _make_button("RESTART", "restart")

func _make_button(text: String, action: String) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_stylebox_override("normal", _round_style(Color(0.07, 0.08, 0.09, 0.62), 18))
    button.add_theme_stylebox_override("pressed", _round_style(Color(0.34, 0.38, 0.36, 0.78), 18))
    button.add_theme_stylebox_override("hover", _round_style(Color(0.12, 0.13, 0.14, 0.72), 18))
    button.pressed.connect(_queue_action.bind(action))
    root.add_child(button)
    return button

func _make_hold_button(text: String) -> Button:
    var button: Button = Button.new()
    button.text = text
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_stylebox_override("normal", _round_style(Color(0.07, 0.08, 0.09, 0.62), 18))
    button.add_theme_stylebox_override("pressed", _round_style(Color(0.34, 0.38, 0.36, 0.78), 18))
    button.add_theme_stylebox_override("hover", _round_style(Color(0.12, 0.13, 0.14, 0.72), 18))
    button.button_down.connect(_set_sprint.bind(true))
    button.button_up.connect(_set_sprint.bind(false))
    root.add_child(button)
    return button

func _round_style(color: Color, radius: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.82, 0.84, 0.84, 0.18)
    return style
