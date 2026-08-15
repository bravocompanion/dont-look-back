extends CharacterBody3D

@export var move_speed: float = 4.0
@export var acceleration: float = 16.0
@export var mouse_sensitivity: float = 0.0022
@export var inventory_capacity: int = 3

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var interaction_hint: Label = $HUD/InteractionHint
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var inventory: Dictionary = {}
var step_timer: float = 0.18

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    add_to_group("player")
    footstep_audio.stream = _build_footstep_stream()
    _update_inventory_hud()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        rotate_y(-event.relative.x * mouse_sensitivity)
        camera.rotate_x(-event.relative.y * mouse_sensitivity)
        camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))

    if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_F:
                flashlight.visible = not flashlight.visible
            KEY_E:
                _try_interact()
            KEY_ESCAPE:
                if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
                    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
                else:
                    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = -0.1

    var x_input: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var z_input: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    var input_vector: Vector2 = Vector2(x_input, z_input)
    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    var direction: Vector3 = (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
    var target_x: float = direction.x * move_speed
    var target_z: float = direction.z * move_speed
    velocity.x = move_toward(velocity.x, target_x, acceleration * delta)
    velocity.z = move_toward(velocity.z, target_z, acceleration * delta)

    move_and_slide()
    _update_footsteps(delta)
    _update_interaction_hint()

func add_item(item_id: String, display_name: String) -> bool:
    if inventory.has(item_id):
        return true
    if inventory.size() >= inventory_capacity:
        return false

    inventory[item_id] = display_name
    _update_inventory_hud()
    return true

func has_item(item_id: String) -> bool:
    return inventory.has(item_id)

func remove_item(item_id: String) -> bool:
    if not inventory.has(item_id):
        return false

    inventory.erase(item_id)
    _update_inventory_hud()
    return true

func _update_inventory_hud() -> void:
    if inventory.is_empty():
        inventory_label.text = "INVENTORY\n(empty)"
        return

    var text: String = "INVENTORY"
    for key in inventory.keys():
        text += "\n• " + str(inventory[key])
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
            interaction_hint.text = "[E] " + str(target.call("get_interaction_text"))

func _update_footsteps(delta: float) -> void:
    var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
    if is_on_floor() and horizontal_speed > 0.45:
        step_timer -= delta
        if step_timer <= 0.0:
            footstep_audio.pitch_scale = 0.97 + 0.035 * sin(float(Time.get_ticks_msec()) / 170.0)
            footstep_audio.play()
            step_timer = 0.46
    else:
        step_timer = 0.16

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
