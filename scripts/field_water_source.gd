extends StaticBody3D

@export var refill_cooldown_seconds: float = 35.0

var next_refill_time: float = 0.0

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var now: float = float(Time.get_ticks_msec()) / 1000.0
    if now < next_refill_time:
        var remaining: int = int(ceil(next_refill_time - now))
        return "Water source recovering (%ds)" % remaining
    return "Collect Dirty Water"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not player.has_method("add_item"):
        return

    var now: float = float(Time.get_ticks_msec()) / 1000.0
    if now < next_refill_time:
        _set_objective(player, "The hand pump needs a moment before more water can be collected.")
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    var accepted: bool = false
    if carry != null and carry.has_method("grant_item"):
        accepted = bool(carry.call("grant_item", player, "dirty_water", "Dirty Water", 1))
    else:
        accepted = bool(player.call("add_item", "dirty_water", "Dirty Water"))

    if not accepted:
        _set_objective(player, "Dirty Water carry limit reached. Store or process water before collecting more.")
        return

    next_refill_time = now + refill_cooldown_seconds
    _set_objective(player, "You collect Dirty Water. Boil it at the shelter campfire before drinking if possible.")
    _report_ai_noise(0.68, "hand water pump")

func _set_objective(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_ai_noise(strength: float, label: String) -> void:
    var noise_relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise_relay == null or not noise_relay.has_method("report_noise"):
        return
    noise_relay.call("report_noise", global_position, strength, label)

func _build_visual() -> void:
    var metal: StandardMaterial3D = StandardMaterial3D.new()
    metal.albedo_color = Color(0.16, 0.19, 0.18, 1.0)
    metal.metallic = 0.72
    metal.roughness = 0.48

    var rust: StandardMaterial3D = StandardMaterial3D.new()
    rust.albedo_color = Color(0.31, 0.12, 0.055, 1.0)
    rust.metallic = 0.35
    rust.roughness = 0.72

    var post_mesh: BoxMesh = BoxMesh.new()
    post_mesh.size = Vector3(0.34, 1.18, 0.34)
    var post: MeshInstance3D = MeshInstance3D.new()
    post.mesh = post_mesh
    post.material_override = metal
    post.position = Vector3(0.0, 0.59, 0.0)
    add_child(post)

    var head_mesh: BoxMesh = BoxMesh.new()
    head_mesh.size = Vector3(0.56, 0.28, 0.42)
    var head: MeshInstance3D = MeshInstance3D.new()
    head.mesh = head_mesh
    head.material_override = rust
    head.position = Vector3(0.0, 1.14, 0.0)
    add_child(head)

    var handle_mesh: BoxMesh = BoxMesh.new()
    handle_mesh.size = Vector3(0.72, 0.08, 0.08)
    var handle: MeshInstance3D = MeshInstance3D.new()
    handle.mesh = handle_mesh
    handle.material_override = metal
    handle.position = Vector3(0.24, 1.30, 0.0)
    handle.rotation.z = -0.28
    add_child(handle)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.75, 1.55, 0.75)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.78, 0.0)
    add_child(collision)
