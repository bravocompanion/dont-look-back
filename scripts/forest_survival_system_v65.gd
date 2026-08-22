extends "res://scripts/forest_survival_system_v64.gd"

# Front-left shelter work area. Cabin frontage faces -Z; campfire is at
# (9.8, 0, -91.4). Keep both utility stations on the cabin's left side (x < 14)
# without blocking the central porch/entry path.
const COOKING_RACK_POSITION_V65: Vector3 = Vector3(12.25, 0.0, -91.25)
const WATER_BOILER_POSITION_V65: Vector3 = Vector3(11.40, 0.0, -89.55)
const CAMPFIRE_POSITION_V65: Vector3 = Vector3(9.80, 0.0, -91.40)

func _spawn_cooking_station() -> void:
    if cooking_script == null or outside_root == null:
        return
    var station: StaticBody3D = outside_root.get_node_or_null("ForestCookingRack") as StaticBody3D
    if station == null:
        station = StaticBody3D.new()
        station.name = "ForestCookingRack"
        station.set_script(cooking_script)
        outside_root.add_child(station)
    station.position = COOKING_RACK_POSITION_V65
    station.rotation.y = 0.0

func get_shelter_work_area_contract_v65() -> Dictionary:
    return {
        "campfire_position": CAMPFIRE_POSITION_V65,
        "cooking_rack_position": COOKING_RACK_POSITION_V65,
        "water_boiler_position": WATER_BOILER_POSITION_V65,
        "front_of_cabin": true,
        "left_of_cabin_center": true,
        "central_entry_path_kept_clear": true
    }
