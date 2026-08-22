extends StaticBody3D

@export var display_name: String = "Shelter Generator"

var powered: bool = false
var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/ShelterSystem")
    if system == null:
        return display_name

    var broken: bool = system.has_method("is_generator_broken_v55") and bool(system.call("is_generator_broken_v55"))
    if broken:
        return "Repair generator (2 Scrap + 1 Electronics)"

    var fuel_percent: int = int(system.call("get_generator_percent")) if system.has_method("get_generator_percent") else 0
    var condition_percent: int = int(system.call("get_generator_condition_percent_v55")) if system.has_method("get_generator_condition_percent_v55") else 100
    if powered:
        return "Refuel generator (Fuel %d%% • Condition %d%%)" % [fuel_percent, condition_percent]
    if fuel_percent > 0:
        return "Restart generator (Fuel %d%% • Condition %d%%)" % [fuel_percent, condition_percent]
    return "Start %s (Fuel Can • Condition %d%%)" % [display_name, condition_percent]

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var system: Node = get_node_or_null("/root/ShelterSystem")
    if system == null:
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var network_client: bool = network != null and network.has_method("is_client") and bool(network.call("is_client"))
    var broken: bool = system.has_method("is_generator_broken_v55") and bool(system.call("is_generator_broken_v55"))

    if broken:
        if network_client:
            if not _player_has_v60(player, "scrap", 2) or not _player_has_v60(player, "electronics", 1):
                _set_objective_v55(player, "Generator repair requires 2 Scrap + 1 Electronics.")
                return
            if network.has_method("request_shared_shelter_action"):
                network.call("request_shared_shelter_action", "generator_repair")
            return

        if system.has_method("repair_generator_v55") and bool(system.call("repair_generator_v55", player)):
            powered = false
            _set_indicator(false)
            _report_ai_noise(1.05, "generator repair")
        return

    var was_powered: bool = powered
    if network_client:
        var percent: int = int(system.call("get_generator_percent")) if system.has_method("get_generator_percent") else 0
        if percent >= 99:
            _set_objective_v55(player, "Generator fuel tank is full.")
            return
        if not _player_has_v60(player, "generator_fuel", 1):
            _set_objective_v55(player, "You have no Fuel Can.")
            return
        if network.has_method("request_shared_shelter_action"):
            network.call("request_shared_shelter_action", "generator_fuel")
        return

    var accepted: bool = false
    if powered and system.has_method("refuel_generator"):
        accepted = bool(system.call("refuel_generator", player))
    elif not powered and system.has_method("activate_generator"):
        accepted = bool(system.call("activate_generator", player))

    if accepted:
        powered = bool(system.call("is_generator_running")) if system.has_method("is_generator_running") else true
        _set_indicator(powered)
        _report_ai_noise(0.62 if was_powered else 1.20, "generator fuel" if was_powered else "generator start")

func set_powered_from_restore(value: bool) -> void:
    powered = value
    _set_indicator(value)

func _player_has_v60(player: CharacterBody3D, item_id: String, amount: int) -> bool:
    if player == null:
        return false
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    return int(counts.get(item_id, 0)) >= amount

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

func _set_objective_v55(player: CharacterBody3D, text: String) -> void:
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_ai_noise(strength: float, label: String) -> void:
    var noise_relay: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise_relay == null or not noise_relay.has_method("report_noise"):
        return
    noise_relay.call("report_noise", global_position, strength, label)

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
