extends CharacterBody3D

@export var move_speed: float = 4.0
@export var acceleration: float = 16.0
@export var mouse_sensitivity: float = 0.0022

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/Flashlight
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var interaction_hint: Label = $HUD/InteractionHint

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    add_to_group("player")

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
    _update_interaction_hint()

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
