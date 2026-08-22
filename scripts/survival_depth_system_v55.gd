extends "res://scripts/survival_depth_system_v54.gd"

const WATER_BOILER_POSITION_V65: Vector3 = Vector3(11.40, 0.0, -89.55)

func _ensure_processing_world(scene: Node) -> void:
    super._ensure_processing_world(scene)
    if scene == null:
        return
    var outside: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside == null:
        return
    var boiler: StaticBody3D = outside.get_node_or_null("WaterBoiler") as StaticBody3D
    if boiler != null and boiler.position != WATER_BOILER_POSITION_V65:
        boiler.position = WATER_BOILER_POSITION_V65
        boiler.rotation.y = 0.0

func get_water_boiler_layout_contract_v65() -> Dictionary:
    return {
        "position": WATER_BOILER_POSITION_V65,
        "front_of_cabin": true,
        "left_of_cabin_center": true,
        "requires_campfire": true
    }
