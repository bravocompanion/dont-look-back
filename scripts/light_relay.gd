extends StaticBody3D

@export var relay_id: int = 0
@export var relay_name: String = "Emergency Relay"

var activated: bool = false
var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    if activated:
        return relay_name + " online"
    return "Restore " + relay_name

func interact() -> void:
    if activated:
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_online") and bool(network.call("is_online")):
        if network.has_method("request_relay_activation"):
            network.call("request_relay_activation", relay_id)
            var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
            if player != null:
                var objective: Label = player.get_node_or_null("HUD/Objective") as Label
                if objective != null:
                    objective.text = "Requesting emergency relay activation from host..."
        return

    var director: Node = get_node_or_null("/root/LabyrinthDirector")
    if director == null or not director.has_method("activate_relay"):
        return

    var accepted: bool = bool(director.call("activate_relay", relay_id))
    if accepted:
        set_activated_from_restore(true)

func set_activated_from_restore(value: bool) -> void:
    activated = value
    if indicator_material == null:
        return
    if activated:
        indicator_material.albedo_color = Color(0.18, 0.65, 0.34, 1.0)
        indicator_material.emission_enabled = true
        indicator_material.emission = Color(0.10, 0.55, 0.24, 1.0)
        indicator_material.emission_energy_multiplier = 2.2
    else:
        indicator_material.albedo_color = Color(0.62, 0.10, 0.08, 1.0)
        indicator_material.emission_enabled = true
        indicator_material.emission = Color(0.45, 0.03, 0.02, 1.0)
        indicator_material.emission_energy_multiplier = 1.4

func _build_visual() -> void:
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(0.62, 0.92, 0.22)

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.11, 0.12, 0.13, 1.0)
    body_material.metallic = 0.35
    body_material.roughness = 0.58

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.58, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.62, 0.92, 0.22)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.58, 0.0)
    add_child(collision)

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(0.30, 0.13, 0.04)
    indicator_material = StandardMaterial3D.new()
    indicator_material.emission_enabled = true
    indicator_material.emission_energy_multiplier = 1.4

    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, 0.72, -0.13)
    add_child(indicator)
    set_activated_from_restore(false)
