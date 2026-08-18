extends "res://scripts/ranger_safe_zone.gd"

const FOREST_RESOURCE_Z: float = -101.0

func _resource_relocation_position(node: Node, y_value: float) -> Vector3:
    var slot: int = absi(hash(str(node.name))) % 7
    var x_value: float = 5.0 + float(slot) * 3.0
    return Vector3(x_value, y_value, FOREST_RESOURCE_Z)
