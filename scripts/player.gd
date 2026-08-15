extends CharacterBody3D

@export var move_speed: float = 4.0
@export var sprint_multiplier: float = 1.65
@export var acceleration: float = 16.0
@export var mouse_sensitivity: float = 0.0022
@export var touch_look_sensitivity: float = 0.0032
@export var inventory_capacity: int = 8

@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var max_stamina: float = 100.0
@export var max_flashlight_battery: float = 100.0
@export var hunger_drain_per_second: float = 0.055
@export var thirst_drain_per_second: float = 0.082
@export var stamina_drain_per_second: float = 25.0
@export var stamina_regen_per_second: float = 18.0
@export var flashlight_drain_per_second: float = 1.15
@export var low_battery_threshold: float = 22.0

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var interaction_hint: Label = $HUD/InteractionHint
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio
@onready var objective_label: Label = $HUD/Objective
@onready var controls_label: Label = $HUD/Controls
@onready var death_panel: ColorRect = $HUD/CaughtPanel
@onready var death_title: Label = $HUD/CaughtPanel/Title
@onready var death_rule: Label = $HUD/CaughtPanel/Rule
@onready var death_restart: Label = $HUD/CaughtPanel/Restart

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var inventory_names: Dictionary = {}
var inventory_counts: Dictionary = {}
var step_timer: float = 0.18

var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var stamina: float = 100.0
var flashlight_battery: float = 100.0
var darkness_exposure: float = 0.0
var flashlight_panic: float = 0.0
var flashlight_base_energy: float = 3.5
var is_dead: bool = false
var is_sprinting: bool = false
var battery_empty_announced: bool = false

var survival_panel: PanelContainer
var health_label: Label
var hunger_label: Label
var thirst_label: Label
var stamina_label: Label
var battery_label: Label
var darkness_label: Label
var damage_flash: ColorRect
var damage_flash_timer: float = 0.0
var starvation_tick_timer: float = 1.0
var light_check_timer: float = 0.0
var ui_check_timer: float = 0.0
var currently_lit: bool = true

func _ready() -> void:
    health = max_health
    hunger = max_hunger
    thirst = max_thirst
    stamina = max_stamina
    flashlight_battery = max_flashlight_battery
    flashlight_base_energy = flashlight.light_energy

    if MobileControls.is_mobile_active():
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    MobileControls.set_dead_mode(false)
    add_to_group("player")
    footstep_audio.stream = _build_footstep_stream()
    _ensure_survival_hud()
    _update_inventory_hud()
    _apply_responsive_hud_layout()
    _update_survival_hud()

    controls_label.text = "WASD Move   Shift Sprint   E Interact   F Flashlight   B Battery   1 Food   2 Water   3 Medkit   M Co-op"

func _process(delta: float) -> void:
    _process_mobile_actions()
    if is_dead:
        return

    hunger = maxf(0.0, hunger - hunger_drain_per_second * delta)
    thirst = maxf(0.0, thirst - thirst_drain_per_second * delta)
    _update_flashlight(delta)

    starvation_tick_timer -= delta
    if starvation_tick_timer <= 0.0:
        starvation_tick_timer = 1.0
        if thirst <= 0.0:
            apply_damage(2.0, "dehydration")
        elif hunger <= 0.0:
            apply_damage(1.0, "starvation")

    light_check_timer -= delta
    if light_check_timer <= 0.0:
        light_check_timer = 0.18
        currently_lit = _is_in_protective_light()

    if currently_lit:
        darkness_exposure = maxf(0.0, darkness_exposure - 24.0 * delta)
    else:
        darkness_exposure = minf(100.0, darkness_exposure + 15.0 * delta)

    if damage_flash_timer > 0.0:
        damage_flash_timer = maxf(0.0, damage_flash_timer - delta)
        var flash_alpha: float = 0.34 * (damage_flash_timer / 0.32)
        damage_flash.color = Color(0.55, 0.0, 0.0, flash_alpha)
    elif damage_flash != null:
        damage_flash.color = Color(0.55, 0.0, 0.0, 0.0)

    ui_check_timer -= delta
    if ui_check_timer <= 0.0:
        ui_check_timer = 0.5
        _apply_responsive_hud_layout()

    _update_survival_hud()

func _process_mobile_actions() -> void:
    if not MobileControls.is_mobile_active():
        return

    if is_dead:
        if MobileControls.consume_action("restart"):
            get_tree().reload_current_scene()
        return

    var touch_look: Vector2 = MobileControls.consume_look_delta()
    if touch_look.length_squared() > 0.0:
        rotate_y(-touch_look.x * touch_look_sensitivity)
        camera.rotate_x(-touch_look.y * touch_look_sensitivity)
        camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))

    if MobileControls.consume_action("interact"):
        _try_interact()
    if MobileControls.consume_action("flashlight"):
        _toggle_flashlight()
    if MobileControls.consume_action("battery"):
        _replace_flashlight_battery()
    if MobileControls.consume_action("food"):
        _consume_food()
    if MobileControls.consume_action("water"):
        _consume_water()
    if MobileControls.consume_action("medkit"):
        _consume_medkit()

func _unhandled_input(event: InputEvent) -> void:
    if is_dead:
        if event is InputEventKey:
            var dead_key: InputEventKey = event as InputEventKey
            if dead_key.pressed and not dead_key.echo and dead_key.physical_keycode == KEY_R:
                get_tree().reload_current_scene()
        return

    if event is InputEventMouseMotion and not MobileControls.is_mobile_active() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        rotate_y(-motion.relative.x * mouse_sensitivity)
        camera.rotate_x(-motion.relative.y * mouse_sensitivity)
        camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))

    if event is InputEventMouseButton and not MobileControls.is_mobile_active():
        var mouse_button: InputEventMouseButton = event as InputEventMouseButton
        if mouse_button.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo:
            match key_event.physical_keycode:
                KEY_F:
                    _toggle_flashlight()
                KEY_B, KEY_4:
                    _replace_flashlight_battery()
                KEY_E:
                    _try_interact()
                KEY_1:
                    _consume_food()
                KEY_2:
                    _consume_water()
                KEY_3:
                    _consume_medkit()
                KEY_ESCAPE:
                    if not MobileControls.is_mobile_active():
                        if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
                        else:
                            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    if is_dead:
        return

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1

    var x_input: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var z_input: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    var input_vector: Vector2 = Vector2(x_input, z_input)

    if MobileControls.is_mobile_active():
        input_vector += MobileControls.get_move_vector()

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    var keyboard_sprint: bool = Input.is_physical_key_pressed(KEY_SHIFT)
    var touch_sprint: bool = MobileControls.is_mobile_active() and MobileControls.is_sprint_pressed()
    var wants_sprint: bool = (keyboard_sprint or touch_sprint) and input_vector.length() > 0.1
    var can_sprint: bool = stamina > 0.5 and hunger > 5.0 and thirst > 5.0
    is_sprinting = wants_sprint and can_sprint

    if is_sprinting:
        stamina = maxf(0.0, stamina - stamina_drain_per_second * delta)
    else:
        var regen_multiplier: float = 1.0
        if hunger < 30.0:
            regen_multiplier *= 0.65
        if thirst < 30.0:
            regen_multiplier *= 0.55
        if darkness_exposure >= 75.0:
            regen_multiplier *= 0.75
        stamina = minf(max_stamina, stamina + stamina_regen_per_second * regen_multiplier * delta)

    var condition_speed_multiplier: float = 1.0
    if hunger < 15.0 or thirst < 15.0:
        condition_speed_multiplier = 0.82

    var current_speed: float = move_speed * condition_speed_multiplier
    if is_sprinting:
        current_speed *= sprint_multiplier

    var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var target_x: float = direction.x * current_speed
    var target_z: float = direction.z * current_speed
    velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

    move_and_slide()
    _update_footsteps(delta)
    _update_interaction_hint()

func add_item(item_id: String, display_name: String) -> bool:
    if inventory_names.has(item_id):
        inventory_counts[item_id] = int(inventory_counts.get(item_id, 0)) + 1
        _update_inventory_hud()
        return true

    if inventory_names.size() >= inventory_capacity:
        return false

    inventory_names[item_id] = display_name
    inventory_counts[item_id] = 1
    _update_inventory_hud()
    return true

func has_item(item_id: String) -> bool:
    return int(inventory_counts.get(item_id, 0)) > 0

func remove_item(item_id: String) -> bool:
    var count: int = int(inventory_counts.get(item_id, 0))
    if count <= 0:
        return false

    count -= 1
    if count <= 0:
        inventory_counts.erase(item_id)
        inventory_names.erase(item_id)
    else:
        inventory_counts[item_id] = count

    _update_inventory_hud()
    return true

func apply_damage(amount: float, source_name: String = "danger") -> bool:
    if is_dead:
        return true

    health = maxf(0.0, health - maxf(0.0, amount))
    damage_flash_timer = 0.32
    objective_label.text = "You were hurt by %s. Find light and recover." % source_name
    _update_survival_hud()

    if health <= 0.0:
        _die(source_name)
        return true
    return false

func heal(amount: float) -> void:
    health = minf(max_health, health + maxf(0.0, amount))
    _update_survival_hud()

func get_darkness_exposure() -> float:
    return darkness_exposure

func get_flashlight_battery() -> float:
    return flashlight_battery

func is_in_light() -> bool:
    return currently_lit

func set_flashlight_panic(panic_value: float) -> void:
    flashlight_panic = clampf(panic_value, 0.0, 100.0)

func _toggle_flashlight() -> void:
    if flashlight.visible:
        flashlight.visible = false
        return

    if flashlight_battery <= 0.0:
        objective_label.text = "The flashlight battery is dead. Replace it with BATT."
        return

    flashlight.visible = true

func _replace_flashlight_battery() -> void:
    if flashlight_battery >= max_flashlight_battery - 1.0:
        objective_label.text = "The flashlight battery is already full."
        return
    if not remove_item("flashlight_battery"):
        objective_label.text = "You have no replacement battery."
        return

    flashlight_battery = max_flashlight_battery
    battery_empty_announced = false
    flashlight.visible = true
    flashlight.light_energy = flashlight_base_energy
    objective_label.text = "You replace the flashlight battery."

func _update_flashlight(delta: float) -> void:
    if flashlight.visible and flashlight_battery > 0.0:
        flashlight_battery = maxf(0.0, flashlight_battery - flashlight_drain_per_second * delta)

    if flashlight_battery <= 0.0:
        flashlight_battery = 0.0
        flashlight.visible = false
        flashlight.light_energy = 0.0
        if not battery_empty_announced:
            battery_empty_announced = true
            objective_label.text = "Your flashlight died. Darkness is not safe. Find a battery."
        return

    if not flashlight.visible:
        flashlight.light_energy = flashlight_base_energy
        return

    var battery_factor: float = 1.0
    if flashlight_battery <= low_battery_threshold:
        var low_ratio: float = clampf(flashlight_battery / low_battery_threshold, 0.0, 1.0)
        var flicker: float = 0.62 + 0.38 * absf(sin(float(Time.get_ticks_msec()) / 72.0))
        battery_factor = lerpf(0.48, 0.88, low_ratio) * flicker

    var panic_factor: float = 1.0
    if flashlight_panic >= 72.0:
        var panic_ratio: float = clampf((flashlight_panic - 72.0) / 28.0, 0.0, 1.0)
        var panic_pulse: float = 0.72 + 0.28 * absf(sin(float(Time.get_ticks_msec()) / 85.0))
        panic_factor = lerpf(1.0, 0.58, panic_ratio) * panic_pulse

    flashlight.light_energy = flashlight_base_energy * battery_factor * panic_factor

func _consume_food() -> void:
    if not remove_item("canned_food"):
        objective_label.text = "You have no food."
        return
    hunger = minf(max_hunger, hunger + 42.0)
    health = minf(max_health, health + 4.0)
    objective_label.text = "You eat the canned food."

func _consume_water() -> void:
    if not remove_item("bottled_water"):
        objective_label.text = "You have no water."
        return
    thirst = minf(max_thirst, thirst + 55.0)
    objective_label.text = "You drink the water."

func _consume_medkit() -> void:
    if health >= max_health:
        objective_label.text = "You do not need the medkit yet."
        return
    if not remove_item("medkit"):
        objective_label.text = "You have no medkit."
        return
    heal(45.0)
    objective_label.text = "You patch your wounds."

func _die(source_name: String) -> void:
    is_dead = true
    velocity = Vector3.ZERO
    is_sprinting = false
    MobileControls.set_dead_mode(MobileControls.is_mobile_active())
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    death_title.text = "YOU DIED"
    death_rule.text = "Cause: %s" % source_name
    death_restart.text = "Tap RESTART" if MobileControls.is_mobile_active() else "Press R to restart"
    death_panel.visible = true
    objective_label.text = ""

    var scene: Node = get_tree().current_scene
    if scene != null:
        var monster: Node = scene.get_node_or_null("Monster")
        if monster != null and monster.has_method("stop_stalking"):
            monster.call("stop_stalking")

func _update_inventory_hud() -> void:
    if inventory_names.is_empty():
        inventory_label.text = "INVENTORY\n(empty)"
        return

    var text: String = "INVENTORY"
    for key_variant: Variant in inventory_names.keys():
        var item_id: String = str(key_variant)
        var item_name: String = str(inventory_names[item_id])
        var count: int = int(inventory_counts.get(item_id, 1))
        text += "\n• %s x%d" % [item_name, count]
    inventory_label.text = text

func _try_interact() -> void:
    interaction_ray.force_raycast_update()
    if not interaction_ray.is_colliding():
        return

    var target: Object = interaction_ray.get_collider()
    if target != null and target.has_method("interact"):
        target.call("interact")

func _update_interaction_hint() -> void:
    interaction_ray.force_raycast_update()
    interaction_hint.text = ""

    if interaction_ray.is_colliding():
        var target: Object = interaction_ray.get_collider()
        if target != null and target.has_method("get_interaction_text"):
            var prefix: String = "[USE] " if MobileControls.is_mobile_active() else "[E] "
            interaction_hint.text = prefix + str(target.call("get_interaction_text"))

func _update_footsteps(delta: float) -> void:
    var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
    if is_on_floor() and horizontal_speed > 0.45:
        step_timer -= delta
        if step_timer <= 0.0:
            footstep_audio.pitch_scale = 1.04 if is_sprinting else 0.97
            footstep_audio.play()
            step_timer = 0.31 if is_sprinting else 0.46
    else:
        step_timer = 0.16

func _ensure_survival_hud() -> void:
    var hud: CanvasLayer = $HUD

    survival_panel = PanelContainer.new()
    survival_panel.name = "SurvivalPanel"
    survival_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(survival_panel)
    survival_panel.anchor_left = 1.0
    survival_panel.anchor_top = 0.0
    survival_panel.anchor_right = 1.0
    survival_panel.anchor_bottom = 0.0

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    survival_panel.add_child(box)

    health_label = _make_stat_label(box)
    hunger_label = _make_stat_label(box)
    thirst_label = _make_stat_label(box)
    stamina_label = _make_stat_label(box)
    battery_label = _make_stat_label(box)
    darkness_label = _make_stat_label(box)

    damage_flash = ColorRect.new()
    damage_flash.name = "DamageFlash"
    damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(damage_flash)
    damage_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
    damage_flash.color = Color(0.55, 0.0, 0.0, 0.0)
    hud.move_child(damage_flash, 1)

func _make_stat_label(parent: VBoxContainer) -> Label:
    var label: Label = Label.new()
    label.add_theme_font_size_override("font_size", 16)
    parent.add_child(label)
    return label

func _apply_responsive_hud_layout() -> void:
    if survival_panel == null:
        return

    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = viewport_size.x < 800.0 or MobileControls.is_mobile_active()

    if compact:
        survival_panel.offset_left = -205.0
        survival_panel.offset_top = 12.0
        survival_panel.offset_right = -12.0
        survival_panel.offset_bottom = 202.0
        objective_label.add_theme_font_size_override("font_size", 16)
        inventory_label.add_theme_font_size_override("font_size", 13)
        inventory_label.offset_top = 52.0
        inventory_label.offset_right = 205.0
        controls_label.visible = false
    else:
        survival_panel.offset_left = -270.0
        survival_panel.offset_top = 70.0
        survival_panel.offset_right = -28.0
        survival_panel.offset_bottom = 276.0
        objective_label.add_theme_font_size_override("font_size", 22)
        inventory_label.add_theme_font_size_override("font_size", 16)
        inventory_label.offset_top = 74.0
        inventory_label.offset_right = 330.0
        controls_label.visible = true

func _update_survival_hud() -> void:
    if health_label == null:
        return
    health_label.text = "HEALTH      %3d / %3d" % [int(round(health)), int(round(max_health))]
    hunger_label.text = "HUNGER      %3d%%" % int(round(hunger))
    thirst_label.text = "THIRST      %3d%%" % int(round(thirst))
    stamina_label.text = "STAMINA     %3d%%" % int(round(stamina))
    battery_label.text = "BATTERY     %3d%%" % int(round(flashlight_battery))
    darkness_label.text = "DARKNESS    %3d%%" % int(round(darkness_exposure))

func _is_in_protective_light() -> bool:
    if flashlight.visible and flashlight_battery > 0.0 and flashlight.light_energy > 0.35:
        return true

    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    return _has_nearby_world_light(scene)

func _has_nearby_world_light(node: Node) -> bool:
    for child: Node in node.get_children():
        if child is OmniLight3D:
            var light: OmniLight3D = child as OmniLight3D
            if light.visible and light.light_energy > 0.1:
                var distance: float = global_position.distance_to(light.global_position)
                if distance <= light.omni_range * 0.82:
                    return true
        if _has_nearby_world_light(child):
            return true
    return false

func _build_footstep_stream() -> AudioStreamWAV:
    var stream: AudioStreamWAV = AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.stereo = false

    var duration: float = 0.12
    var sample_count: int = int(float(stream.mix_rate) * duration)
    var data: PackedByteArray = PackedByteArray()
    data.resize(sample_count * 2)

    for i: int in range(sample_count):
        var t: float = float(i) / float(stream.mix_rate)
        var envelope: float = exp(-t * 30.0)
        var tone: float = sin(TAU * 68.0 * t) * 0.72 + sin(TAU * 108.0 * t) * 0.28
        var sample: int = clampi(int(tone * envelope * 9000.0), -32768, 32767)
        var encoded: int = sample
        if encoded < 0:
            encoded += 65536
        data[i * 2] = encoded & 255
        data[i * 2 + 1] = (encoded >> 8) & 255

    stream.data = data
    return stream
