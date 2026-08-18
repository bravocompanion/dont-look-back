extends "res://scripts/forest_survival_system_v26.gd"

## v0.27 forest scale pass.
## Spreads wildlife and fishing across the new 224m x 304m forest so the
## enlarged map does not feel empty and no wildlife starts inside Ranger Yard.

func _spawn_fishing_spots() -> void:
    if fishing_script == null:
        return
    var spots: Array[Dictionary] = [
        {"id": "pond_north", "position": Vector3(-78.0, 0.0, -205.0)},
        {"id": "pond_south", "position": Vector3(70.0, 0.0, -340.0)}
    ]
    for data: Dictionary in spots:
        var node_name: String = "FishingSpot_%s" % str(data.get("id", "x"))
        if outside_root.has_node(NodePath(node_name)):
            continue
        var spot: StaticBody3D = StaticBody3D.new()
        spot.name = node_name
        spot.set_script(fishing_script)
        spot.set("spot_id", str(data.get("id", "pond")))
        spot.position = Vector3(data.get("position", Vector3.ZERO))
        outside_root.add_child(spot)

func _build_wildlife_specs() -> void:
    animal_specs = {
        "deer_a": {"kind": "deer", "position": Vector3(-48.0, 0.0, -138.0)},
        "deer_b": {"kind": "deer", "position": Vector3(72.0, 0.0, -198.0)},
        "deer_c": {"kind": "deer", "position": Vector3(-62.0, 0.0, -252.0)},
        "rabbit_a": {"kind": "rabbit", "position": Vector3(42.0, 0.0, -126.0)},
        "rabbit_b": {"kind": "rabbit", "position": Vector3(-88.0, 0.0, -214.0)},
        "rabbit_c": {"kind": "rabbit", "position": Vector3(45.0, 0.0, -304.0)},
        "rabbit_d": {"kind": "rabbit", "position": Vector3(-24.0, 0.0, -333.0)},
        "boar_a": {"kind": "boar", "position": Vector3(-82.0, 0.0, -274.0)},
        "boar_b": {"kind": "boar", "position": Vector3(84.0, 0.0, -245.0)},
        "wolf_a": {"kind": "wolf", "position": Vector3(86.0, 0.0, -323.0)},
        "wolf_b": {"kind": "wolf", "position": Vector3(-94.0, 0.0, -338.0)}
    }
