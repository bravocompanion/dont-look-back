extends StaticBody3D

@export var display_name: String = "Shelter Generator"

var powered: bool = false
var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/ShelterSystem")
    if system != null and system.has_method("get_generator_percent"):
        var percent: int = int(system.call("get_generator_percent"))
        if powered:
            return "Refuel generator (%d%%)" % percent
    return "Start " + display_name + " (Fuel Can)"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var system: Node = get_node_or_null("/root/ShelterSystem")
    if system == null:
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var network_client: bool = network != null and network.has_method("is_client") and bool(network.call("is_client"))
    if network_client:
        var percent: int = int(system.call("get_generator_percent")) if system.has_method("get_generator_percent") else 0
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if percent >= 99:
            if objective != null:
                objective.text = "Generator fuel tank is full."
            return
        if not player.has_method("remove_item") or not bool(player.call("remove_item", "generator_fuel")):
            if objective != null:
                objective.text = "You have no Fuel Can."
            return
        if network.has_method("request_shared_shelter_action"):
            network.call("request_shared_shelter_action", "generator_fuel")
        if objective != null:
            objective.text = "Fuel request sent to host."
        return

    var accepted: bool = false
    if powered and system.has_method("refuel_generator"):
        accepted = bool(system.call("refuel_generator", player))
    elif not powered and system.has_method("activate_generator"):
        accepted = bool(system.call("activate_generator", player))

    if accepted:
        powered = bool(system.call("is_generator_running")) if system.has_method("is_generator_running") else true
        _set_indicator(powered)

func set_powered_from_restore(value: bool) -> void:
    powered = value
    _set_indicator(value)

func _set_indicator(value: bool) -> void:
    if indicator_material == null:
        return
    if value:
        indicator_material.albedo_color = Color(0.18, 0.65, 0.34, 1.0)
        indicator_material.emission = Color(0.10, 0.55, 0.24, 1.0)
        indicator_material.emission_energy_multiplier = 2.4
    else:
        indicator_material.albedo_color = Color(0.55, 0.10, 0.07, 1.0)
        indicator_material.emission = Color(0.42, 0.03, 0.02, 1.0)
        indicator_material.emission_energy_multiplier = 1.5

func _build_visual() -> void:
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.15, 0.82, 0.70)

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.12, 0.13, 0.12, 1.0)
    body_material.metallic = 0.42
    body_material.roughness = 0.58

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.48, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = body_mesh.size
    collision.shape = shape
    collision.position = body.position
    add_child(collision)

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(0.36, 0.14, 0.05)

    indicator_material = StandardMaterial3D.new()
    indicator_material.emission_enabled = true
    _set_indicator(false)

    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, 0.62, -0.38)
    add_child(indicator)
