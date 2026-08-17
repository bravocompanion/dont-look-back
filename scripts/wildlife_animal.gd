extends CharacterBody3D

@export var animal_id: String = "wildlife"
@export var animal_kind: String = "deer"
@export var move_speed: float = 2.2
@export var max_health: float = 2.0
@export var alert_radius: float = 9.0
@export var attack_damage: float = 8.0
@export var attack_distance: float = 1.25
@export var attack_cooldown: float = 2.0
@export var wander_radius: float = 8.0

var home_position: Vector3 = Vector3.ZERO
var current_health: float = 2.0
var alive: bool = true
var remote_controlled: bool = false
var remote_position: Vector3 = Vector3.ZERO
var remote_yaw: float = 0.0
var retarget_timer: float = 0.0
var attack_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wounded_seconds: float = 0.0
var blood_mark_timer: float = 0.0

func _ready() -> void:
    add_to_group("wildlife")
    call_deferred("_finish_setup")

func _finish_setup() -> void:
    if not is_inside_tree():
        return
    _apply_kind_stats()
    rng.seed = int(abs(hash(animal_id))) + 1337
    home_position = global_position
    current_health = max_health
    remote_position = global_position
    wander_target = global_position
    _build_visual()
    _build_collision()

func configure(id_value: String, kind_value: String, spawn_position: Vector3, is_remote: bool) -> void:
    animal_id = id_value
    animal_kind = kind_value
    global_position = spawn_position
    home_position = spawn_position
    remote_position = spawn_position
    remote_controlled = is_remote
    _apply_kind_stats()
    current_health = max_health

func _physics_process(delta: float) -> void:
    if remote_controlled or not alive:
        velocity = Vector3.ZERO
        return

    attack_timer = maxf(0.0, attack_timer - delta)
    retarget_timer -= delta
    _update_wound_trail(delta)

    var nearest: CharacterBody3D = _nearest_player()
    var goal: Vector3 = wander_target
    var speed: float = move_speed

    if nearest != null:
        var offset: Vector3 = nearest.global_position - global_position
        offset.y = 0.0
        var distance: float = offset.length()
        var hostile: bool = animal_kind == "wolf" or animal_kind == "boar"
        var alerted_by_wound: bool = wounded_seconds > 0.0 and distance <= alert_radius * 2.2

        if hostile and (distance <= alert_radius or alerted_by_wound):
            goal = nearest.global_position
            speed *= 1.18 if animal_kind == "wolf" else 1.28
            if distance <= attack_distance and attack_timer <= 0.0:
                _attack_player(nearest)
        elif not hostile and (distance <= alert_radius or alerted_by_wound):
            var away: Vector3 = -offset.normalized() if distance > 0.05 else Vector3(1.0, 0.0, 0.0)
            goal = global_position + away * 13.0
            speed *= 1.70 if animal_kind == "rabbit" else 1.48
        elif retarget_timer <= 0.0:
            _pick_wander_target()
            goal = wander_target
    elif retarget_timer <= 0.0:
        _pick_wander_target()
        goal = wander_target

    var direction: Vector3 = goal - global_position
    direction.y = 0.0
    if direction.length() > 0.22:
        direction = direction.normalized()
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
        rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), clampf(delta * 7.0, 0.0, 1.0))
    else:
        velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 6.0 * delta)

    move_and_slide()

func _process(delta: float) -> void:
    if not remote_controlled or not alive:
        return
    global_position = global_position.lerp(remote_position, clampf(delta * 10.0, 0.0, 1.0))
    rotation.y = lerp_angle(rotation.y, remote_yaw, clampf(delta * 9.0, 0.0, 1.0))

func take_hunting_damage(amount: float, hunter_peer_id: int) -> void:
    if not alive or remote_controlled:
        return
    current_health = maxf(0.0, current_health - maxf(0.0, amount))
    retarget_timer = 0.0
    wounded_seconds = 13.0
    blood_mark_timer = 0.0

    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if current_health <= 0.0:
        alive = false
        visible = false
        velocity = Vector3.ZERO
        _set_collision_enabled(false)
        if system != null and system.has_method("on_animal_killed"):
            system.call("on_animal_killed", animal_id, animal_kind, hunter_peer_id, global_position)
        return

    if system != null and system.has_method("on_animal_wounded"):
        system.call("on_animal_wounded", animal_id, animal_kind, global_position)

func _update_wound_trail(delta: float) -> void:
    if wounded_seconds <= 0.0:
        return
    wounded_seconds = maxf(0.0, wounded_seconds - delta)
    blood_mark_timer -= delta
    if blood_mark_timer > 0.0:
        return
    blood_mark_timer = 1.75 if animal_kind != "rabbit" else 1.2
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("on_animal_blood_trail"):
        system.call("on_animal_blood_trail", global_position, animal_kind)

func apply_remote_state(position_value: Vector3, yaw: float, alive_value: bool, health_value: float) -> void:
    remote_position = position_value
    remote_yaw = yaw
    current_health = health_value
    if alive != alive_value:
        alive = alive_value
        visible = alive
        _set_collision_enabled(alive)

func reset_animal(spawn_position: Vector3) -> void:
    global_position = spawn_position
    home_position = spawn_position
    remote_position = spawn_position
    current_health = max_health
    alive = true
    visible = true
    velocity = Vector3.ZERO
    retarget_timer = 0.0
    wounded_seconds = 0.0
    blood_mark_timer = 0.0
    _set_collision_enabled(true)
    _pick_wander_target()

func _pick_wander_target() -> void:
    retarget_timer = rng.randf_range(2.5, 6.5)
    var angle: float = rng.randf_range(0.0, TAU)
    var radius: float = rng.randf_range(1.5, wander_radius)
    wander_target = home_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

func _nearest_player() -> CharacterBody3D:
    var best: CharacterBody3D
    var best_distance: float = INF
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null or bool(player.get("is_dead")):
            continue
        var distance: float = Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
        if distance < best_distance:
            best_distance = distance
            best = player
    return best

func _attack_player(player: CharacterBody3D) -> void:
    attack_timer = attack_cooldown
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("report_wildlife_attack"):
        system.call("report_wildlife_attack", player, attack_damage, animal_kind)
    elif player.has_method("apply_damage"):
        player.call("apply_damage", attack_damage, animal_kind)

func _apply_kind_stats() -> void:
    match animal_kind:
        "rabbit":
            move_speed = 2.8
            max_health = 1.0
            alert_radius = 8.5
            wander_radius = 6.0
        "boar":
            move_speed = 2.5
            max_health = 3.0
            alert_radius = 6.5
            attack_damage = 14.0
            wander_radius = 8.0
        "wolf":
            move_speed = 3.0
            max_health = 3.0
            alert_radius = 12.0
            attack_damage = 16.0
            wander_radius = 10.0
        _:
            move_speed = 2.2
            max_health = 2.0
            alert_radius = 10.0
            wander_radius = 9.0

func _build_visual() -> void:
    if get_node_or_null("Body") != null:
        return

    var material: StandardMaterial3D = StandardMaterial3D.new()
    match animal_kind:
        "rabbit": material.albedo_color = Color(0.50, 0.47, 0.42, 1.0)
        "boar": material.albedo_color = Color(0.19, 0.15, 0.12, 1.0)
        "wolf": material.albedo_color = Color(0.32, 0.33, 0.34, 1.0)
        _: material.albedo_color = Color(0.38, 0.25, 0.14, 1.0)
    material.roughness = 1.0

    var body_mesh: CapsuleMesh = CapsuleMesh.new()
    var body_scale: Vector3 = Vector3.ONE
    var body_height: float = 1.0
    match animal_kind:
        "rabbit":
            body_mesh.radius = 0.20
            body_mesh.height = 0.50
            body_height = 0.28
            body_scale = Vector3(0.9, 0.75, 1.2)
        "boar":
            body_mesh.radius = 0.38
            body_mesh.height = 1.05
            body_height = 0.50
            body_scale = Vector3(1.0, 0.8, 1.45)
        "wolf":
            body_mesh.radius = 0.30
            body_mesh.height = 1.10
            body_height = 0.48
            body_scale = Vector3(0.85, 0.78, 1.55)
        _:
            body_mesh.radius = 0.34
            body_mesh.height = 1.20
            body_height = 0.78
            body_scale = Vector3(0.95, 1.0, 1.55)

    var body: MeshInstance3D = MeshInstance3D.new()
    body.name = "Body"
    body.mesh = body_mesh
    body.material_override = material
    body.position = Vector3(0.0, body_height, 0.0)
    body.scale = body_scale
    add_child(body)

    var head_mesh: SphereMesh = SphereMesh.new()
    head_mesh.radius = 0.24 if animal_kind != "rabbit" else 0.16
    head_mesh.height = head_mesh.radius * 2.0
    var head: MeshInstance3D = MeshInstance3D.new()
    head.name = "Head"
    head.mesh = head_mesh
    head.material_override = material
    var head_y: float = 0.90 if animal_kind == "deer" else (0.52 if animal_kind == "rabbit" else 0.62)
    var head_z: float = -0.58 if animal_kind != "rabbit" else -0.30
    head.position = Vector3(0.0, head_y, head_z)
    add_child(head)

func _build_collision() -> void:
    if get_node_or_null("CollisionShape3D") != null:
        return
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape: CapsuleShape3D = CapsuleShape3D.new()
    match animal_kind:
        "rabbit":
            shape.radius = 0.24
            shape.height = 0.52
            collision.position = Vector3(0.0, 0.28, 0.0)
        "boar", "wolf":
            shape.radius = 0.42
            shape.height = 1.12
            collision.position = Vector3(0.0, 0.55, 0.0)
        _:
            shape.radius = 0.42
            shape.height = 1.42
            collision.position = Vector3(0.0, 0.72, 0.0)
    collision.shape = shape
    add_child(collision)

func _set_collision_enabled(enabled: bool) -> void:
    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null:
        collision.disabled = not enabled
