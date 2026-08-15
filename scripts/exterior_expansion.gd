extends Node

var configured_scene_id: int = 0
var outside_root: Node3D
var expansion_root: Node3D
var expansion_daylight: OmniLight3D
var gas_emergency_light: OmniLight3D
var pickup_script: Script
var water_script: Script
var landmark_script: Script

func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    water_script = load("res://scripts/field_water_source.gd") as Script
    landmark_script = load("res://scripts/exterior_landmark.gd") as Script

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        outside_root = null
        expansion_root = null
        expansion_daylight = null
        gas_emergency_light = null

    if expansion_root == null or not is_instance_valid(expansion_root):
        outside_root = scene.get_node_or_null("OutsideWorld") as Node3D
        if outside_root == null:
            return
        _build_expansion()

    _update_expansion_lighting()

func _build_expansion() -> void:
    if outside_root == null:
        return

    var existing: Node3D = outside_root.get_node_or_null("ExteriorExpansion") as Node3D
    if existing != null:
        expansion_root = existing
        expansion_daylight = expansion_root.get_node_or_null("ExpansionDaylightProtection") as OmniLight3D
        gas_emergency_light = expansion_root.get_node_or_null("GasEmergencyLight") as OmniLight3D
        return

    var old_boundary: Node = outside_root.get_node_or_null("FarBoundary")
    if old_boundary != null:
        old_boundary.queue_free()

    expansion_root = Node3D.new()
    expansion_root.name = "ExteriorExpansion"
    outside_root.add_child(expansion_root)

    var ground: StandardMaterial3D = _make_material(Color(0.045, 0.058, 0.045, 1.0), 0.98)
    var road: StandardMaterial3D = _make_material(Color(0.068, 0.068, 0.064, 1.0), 0.94)
    var wood: StandardMaterial3D = _make_material(Color(0.12, 0.078, 0.042, 1.0), 0.94)
    var concrete: StandardMaterial3D = _make_material(Color(0.12, 0.125, 0.12, 1.0), 0.92)
    var metal: StandardMaterial3D = _make_material(Color(0.11, 0.12, 0.12, 1.0), 0.72, 0.38)
    var dark: StandardMaterial3D = _make_material(Color(0.028, 0.032, 0.028, 1.0), 1.0)
    var rust: StandardMaterial3D = _make_material(Color(0.24, 0.075, 0.035, 1.0), 0.72, 0.28)

    _add_box("ExpansionGround", Vector3(0.0, -0.12, -168.0), Vector3(112.0, 0.24, 72.0), ground)
    _add_box("ExpansionRoad", Vector3(0.0, 0.01, -163.0), Vector3(5.4, 0.04, 62.0), road)
    _add_box("HouseTrack", Vector3(-13.0, 0.015, -150.0), Vector3(23.0, 0.035, 3.4), road)
    _add_box("GasTrack", Vector3(12.0, 0.015, -161.0), Vector3(20.0, 0.035, 3.4), road)
    _add_box("WarehouseTrack", Vector3(-4.0, 0.015, -185.0), Vector3(14.0, 0.035, 3.6), road)

    _add_box("ExpansionLeftBoundary", Vector3(-56.0, 1.4, -168.0), Vector3(0.40, 2.8, 72.0), dark)
    _add_box("ExpansionRightBoundary", Vector3(56.0, 1.4, -168.0), Vector3(0.40, 2.8, 72.0), dark)
    _add_box("ExpansionFarBoundary", Vector3(0.0, 1.4, -204.0), Vector3(112.0, 2.8, 0.40), dark)

    _build_abandoned_house(wood, dark)
    _build_gas_station(concrete, metal, rust)
    _build_warehouse(metal, concrete, dark)
    _build_deep_forest(dark)
    _build_water_source()
    _spawn_expansion_loot()
    _spawn_landmarks()
    _build_lights()

func _build_abandoned_house(wood: Material, dark: Material) -> void:
    _add_box("HouseFloor", Vector3(-25.0, 0.08, -150.0), Vector3(10.0, 0.18, 8.0), wood)
    _add_box("HouseRoof", Vector3(-25.0, 3.15, -150.0), Vector3(10.4, 0.28, 8.4), dark)
    _add_box("HouseLeft", Vector3(-30.0, 1.55, -150.0), Vector3(0.22, 3.0, 8.0), wood)
    _add_box("HouseRight", Vector3(-20.0, 1.55, -150.0), Vector3(0.22, 3.0, 8.0), wood)
    _add_box("HouseBack", Vector3(-25.0, 1.55, -154.0), Vector3(10.0, 3.0, 0.22), wood)
    _add_box("HouseFrontLeft", Vector3(-28.3, 1.55, -146.0), Vector3(3.4, 3.0, 0.22), wood)
    _add_box("HouseFrontRight", Vector3(-21.7, 1.55, -146.0), Vector3(3.4, 3.0, 0.22), wood)
    _add_box("HouseDivider", Vector3(-25.0, 1.55, -151.5), Vector3(0.18, 3.0, 5.0), wood)
    _add_box("HouseTable", Vector3(-27.0, 0.72, -152.3), Vector3(1.8, 0.16, 0.8), wood)

func _build_gas_station(concrete: Material, metal: Material, rust: Material) -> void:
    _add_box("GasPad", Vector3(22.0, 0.06, -160.0), Vector3(15.0, 0.12, 12.0), concrete)
    _add_box("GasCanopy", Vector3(22.0, 3.35, -159.0), Vector3(12.5, 0.24, 7.0), metal)
    _add_box("GasCanopyPostA", Vector3(17.5, 1.70, -159.0), Vector3(0.35, 3.4, 0.35), metal)
    _add_box("GasCanopyPostB", Vector3(26.5, 1.70, -159.0), Vector3(0.35, 3.4, 0.35), metal)
    _add_box("GasPumpA", Vector3(20.0, 0.65, -159.0), Vector3(0.75, 1.30, 0.55), rust)
    _add_box("GasPumpB", Vector3(24.0, 0.65, -159.0), Vector3(0.75, 1.30, 0.55), rust)

    _add_box("GasStoreFloor", Vector3(25.5, 0.08, -164.0), Vector3(8.0, 0.18, 6.0), concrete)
    _add_box("GasStoreRoof", Vector3(25.5, 2.75, -164.0), Vector3(8.3, 0.24, 6.3), metal)
    _add_box("GasStoreLeft", Vector3(21.5, 1.38, -164.0), Vector3(0.22, 2.6, 6.0), concrete)
    _add_box("GasStoreRight", Vector3(29.5, 1.38, -164.0), Vector3(0.22, 2.6, 6.0), concrete)
    _add_box("GasStoreBack", Vector3(25.5, 1.38, -167.0), Vector3(8.0, 2.6, 0.22), concrete)
    _add_box("GasStoreFrontLeft", Vector3(23.1, 1.38, -161.0), Vector3(3.1, 2.6, 0.22), concrete)
    _add_box("GasStoreFrontRight", Vector3(28.1, 1.38, -161.0), Vector3(2.8, 2.6, 0.22), concrete)

func _build_warehouse(metal: Material, concrete: Material, dark: Material) -> void:
    _add_box("WarehouseFloor", Vector3(-8.0, 0.08, -187.0), Vector3(16.0, 0.18, 11.0), concrete)
    _add_box("WarehouseRoof", Vector3(-8.0, 4.10, -187.0), Vector3(16.4, 0.28, 11.4), dark)
    _add_box("WarehouseLeft", Vector3(-16.0, 2.0, -187.0), Vector3(0.24, 4.0, 11.0), metal)
    _add_box("WarehouseRight", Vector3(0.0, 2.0, -187.0), Vector3(0.24, 4.0, 11.0), metal)
    _add_box("WarehouseBack", Vector3(-8.0, 2.0, -192.5), Vector3(16.0, 4.0, 0.24), metal)
    _add_box("WarehouseFrontLeft", Vector3(-13.2, 2.0, -181.5), Vector3(5.6, 4.0, 0.24), metal)
    _add_box("WarehouseFrontRight", Vector3(-2.8, 2.0, -181.5), Vector3(5.6, 4.0, 0.24), metal)
    _add_box("WarehouseShelfA", Vector3(-12.0, 1.0, -188.5), Vector3(0.8, 2.0, 4.5), metal)
    _add_box("WarehouseShelfB", Vector3(-4.0, 1.0, -188.5), Vector3(0.8, 2.0, 4.5), metal)

func _build_deep_forest(material: Material) -> void:
    var tree_positions: Array[Vector3] = [
        Vector3(-43.0, 0.0, -140.0), Vector3(43.0, 0.0, -142.0),
        Vector3(-36.0, 0.0, -158.0), Vector3(39.0, 0.0, -174.0),
        Vector3(-47.0, 0.0, -181.0), Vector3(47.0, 0.0, -191.0),
        Vector3(-30.0, 0.0, -197.0), Vector3(27.0, 0.0, -196.0),
        Vector3(11.0, 0.0, -145.0), Vector3(-15.0, 0.0, -166.0),
        Vector3(12.0, 0.0, -176.0), Vector3(34.0, 0.0, -184.0),
        Vector3(-34.0, 0.0, -171.0), Vector3(48.0, 0.0, -157.0)
    ]
    var index: int = 0
    for tree_position: Vector3 in tree_positions:
        index += 1
        _add_box("ExpansionTree%d" % index, tree_position + Vector3(0.0, 2.0, 0.0), Vector3(0.62, 4.0, 0.62), material)

func _build_water_source() -> void:
    if water_script == null:
        return
    var pump: StaticBody3D = StaticBody3D.new()
    pump.name = "OldWaterPump"
    pump.set_script(water_script)
    pump.position = Vector3(31.0, 0.0, -188.0)
    expansion_root.add_child(pump)

func _spawn_expansion_loot() -> void:
    _spawn_pickup("HouseFoodA", "canned_food", "Canned Food", Vector3(-27.0, 0.90, -152.3))
    _spawn_pickup("HouseMedkit", "medkit", "Medkit", Vector3(-22.0, 0.02, -152.0))
    _spawn_pickup("HouseBattery", "flashlight_battery", "Flashlight Battery", Vector3(-28.5, 0.02, -148.0))

    _spawn_pickup("GasFuelA", "generator_fuel", "Fuel Can", Vector3(20.0, 0.02, -157.3))
    _spawn_pickup("GasFuelB", "generator_fuel", "Fuel Can", Vector3(27.4, 0.02, -165.0))
    _spawn_pickup("GasWater", "bottled_water", "Bottled Water", Vector3(23.0, 0.02, -165.5))
    _spawn_pickup("GasScrap", "scrap", "Scrap", Vector3(28.2, 0.02, -162.5))

    _spawn_pickup("WarehouseScrapA", "scrap", "Scrap", Vector3(-12.0, 0.02, -189.5))
    _spawn_pickup("WarehouseScrapB", "scrap", "Scrap", Vector3(-4.0, 0.02, -190.0))
    _spawn_pickup("WarehouseWoodA", "wood", "Wood", Vector3(-10.5, 0.02, -184.0))
    _spawn_pickup("WarehouseWoodB", "wood", "Wood", Vector3(-5.5, 0.02, -184.5))
    _spawn_pickup("WarehouseBattery", "flashlight_battery", "Flashlight Battery", Vector3(-8.0, 0.02, -191.0))
    _spawn_pickup("FarMedkit", "medkit", "Medkit", Vector3(42.0, 0.02, -195.0))

func _spawn_pickup(node_name: String, item_id: String, display_name: String, position: Vector3) -> void:
    if pickup_script == null or expansion_root == null:
        return
    if expansion_root.has_node(NodePath(node_name)):
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../../Player/HUD/Objective"))
    pickup.position = position
    expansion_root.add_child(pickup)

func _spawn_landmarks() -> void:
    _add_landmark("HouseLandmark", Vector3(-25.0, 1.0, -146.5), Vector3(10.0, 2.0, 4.0), "ABANDONED HOUSE", "Search the rooms. The interior stays dangerous after sunset.")
    _add_landmark("GasLandmark", Vector3(22.0, 1.0, -156.0), Vector3(16.0, 2.0, 5.0), "OLD GAS STATION", "Fuel is valuable here, but the lights are nearly dead.")
    _add_landmark("WarehouseLandmark", Vector3(-8.0, 1.0, -180.5), Vector3(17.0, 2.0, 4.0), "WAREHOUSE", "Scrap and wood remain inside. Do not stay after dark.")
    _add_landmark("PumpLandmark", Vector3(31.0, 1.0, -187.0), Vector3(6.0, 2.0, 6.0), "OLD WATER PUMP", "This is the first renewable water source outside the shelter.")

func _add_landmark(node_name: String, position: Vector3, size: Vector3, landmark_name: String, objective_text: String) -> void:
    if landmark_script == null:
        return
    var area: Area3D = Area3D.new()
    area.name = StringName(node_name)
    area.set_script(landmark_script)
    area.set("landmark_name", landmark_name)
    area.set("objective_text", objective_text)
    area.position = position
    expansion_root.add_child(area)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    area.add_child(collision)

func _build_lights() -> void:
    expansion_daylight = OmniLight3D.new()
    expansion_daylight.name = "ExpansionDaylightProtection"
    expansion_daylight.position = Vector3(0.0, 5.0, -169.0)
    expansion_daylight.light_color = Color(0.58, 0.62, 0.56, 1.0)
    expansion_daylight.light_energy = 0.0
    expansion_daylight.omni_range = 88.0
    expansion_daylight.shadow_enabled = false
    expansion_root.add_child(expansion_daylight)

    gas_emergency_light = OmniLight3D.new()
    gas_emergency_light.name = "GasEmergencyLight"
    gas_emergency_light.position = Vector3(25.5, 2.35, -164.0)
    gas_emergency_light.light_color = Color(0.52, 0.18, 0.10, 1.0)
    gas_emergency_light.light_energy = 0.26
    gas_emergency_light.omni_range = 5.2
    gas_emergency_light.shadow_enabled = true
    expansion_root.add_child(gas_emergency_light)

func _update_expansion_lighting() -> void:
    if expansion_daylight == null or not is_instance_valid(expansion_daylight):
        return
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return

    var minute: float = float(outside.get("game_minutes"))
    var daylight: float = 0.0
    if minute >= 420.0 and minute < 1020.0:
        daylight = 1.0
    elif minute >= 1020.0 and minute < 1140.0:
        daylight = 1.0 - clampf((minute - 1020.0) / 120.0, 0.0, 1.0)
    elif minute >= 300.0 and minute < 420.0:
        daylight = clampf((minute - 300.0) / 120.0, 0.0, 1.0)

    expansion_daylight.light_energy = 0.34 * daylight
    if gas_emergency_light != null and is_instance_valid(gas_emergency_light):
        gas_emergency_light.light_energy = 0.18 if daylight > 0.25 else 0.32

func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> StaticBody3D:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = StringName(node_name)
    body.position = position
    expansion_root.add_child(body)

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    body.add_child(mesh_instance)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    return body

func _make_material(color: Color, roughness: float, metallic: float = 0.0) -> StandardMaterial3D:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material
