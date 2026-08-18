extends "res://scripts/forest_world_expansion_v2.gd"

const MINE_CENTER: Vector3 = Vector3(-98.0, 0.0, -338.0)

func _build_long_distance_trails() -> void:
    var trail_material: StandardMaterial3D = StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.075, 0.067, 0.050, 1.0)
    trail_material.roughness = 1.0

    _add_trail_segment("TrailCabinToHouse", Vector3(14.0, 0.015, -97.0), HOUSE_CENTER, 3.2, trail_material)
    _add_trail_segment("TrailHouseToGas", HOUSE_CENTER, GAS_CENTER, 2.8, trail_material)
    _add_trail_segment("TrailGasToWarehouse", GAS_CENTER, WAREHOUSE_CENTER, 2.7, trail_material)
    _add_trail_segment("TrailWarehouseToMine", WAREHOUSE_CENTER, MINE_CENTER, 2.6, trail_material)
    _add_trail_segment("TrailMineToPump", MINE_CENTER, PUMP_CENTER, 2.3, trail_material)
