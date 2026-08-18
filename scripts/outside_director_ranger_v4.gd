extends "res://scripts/outside_director_ranger_v3.gd"

const CABIN_CENTER_V31: Vector3 = Vector3(14.0, 0.0, -82.0)
const CABIN_WIDTH_V31: float = 12.0
const CABIN_DEPTH_V31: float = 10.5
const CABIN_HALF_WIDTH_V31: float = CABIN_WIDTH_V31 * 0.5
const CABIN_HALF_DEPTH_V31: float = CABIN_DEPTH_V31 * 0.5
const CABIN_BACK_Z_V31: float = -76.75
const CABIN_FRONT_Z_V31: float = -87.25

## v0.31 cabin footprint is 1.5x the previous width and depth.
## The front/porch continues to face deep forest (-Z).
func _build_cabin(material: Material) -> void:
    if outside_root == null:
        return

    var wall_height: float = 3.45
    var wall_center_y: float = wall_height * 0.5
    var roof_y: float = wall_height + 0.18

    _add_csg_box(
        outside_root,
        "CabinFloor",
        Vector3(CABIN_CENTER_V31.x, 0.08, CABIN_CENTER_V31.z),
        Vector3(CABIN_WIDTH_V31, 0.18, CABIN_DEPTH_V31),
        material
    )
    _add_csg_box(
        outside_root,
        "CabinRoof",
        Vector3(CABIN_CENTER_V31.x, roof_y, CABIN_CENTER_V31.z),
        Vector3(CABIN_WIDTH_V31 + 0.65, 0.30, CABIN_DEPTH_V31 + 0.65),
        material
    )
    _add_csg_box(
        outside_root,
        "CabinLeft",
        Vector3(CABIN_CENTER_V31.x - CABIN_HALF_WIDTH_V31, wall_center_y, CABIN_CENTER_V31.z),
        Vector3(0.22, wall_height, CABIN_DEPTH_V31),
        material
    )
    _add_csg_box(
        outside_root,
        "CabinRight",
        Vector3(CABIN_CENTER_V31.x + CABIN_HALF_WIDTH_V31, wall_center_y, CABIN_CENTER_V31.z),
        Vector3(0.22, wall_height, CABIN_DEPTH_V31),
        material
    )

    # Back wall faces the map-edge side (+Z).
    _add_csg_box(
        outside_root,
        "CabinBack",
        Vector3(CABIN_CENTER_V31.x, wall_center_y, CABIN_BACK_Z_V31),
        Vector3(CABIN_WIDTH_V31, wall_height, 0.22),
        material
    )

    # 3 m central doorway faces the mission route/deep forest (-Z).
    _add_csg_box(
        outside_root,
        "CabinFrontLeft",
        Vector3(10.25, wall_center_y, CABIN_FRONT_Z_V31),
        Vector3(4.5, wall_height, 0.22),
        material
    )
    _add_csg_box(
        outside_root,
        "CabinFrontRight",
        Vector3(17.75, wall_center_y, CABIN_FRONT_Z_V31),
        Vector3(4.5, wall_height, 0.22),
        material
    )

    # Central planning table leaves a clear path from the door to both sides.
    _add_csg_box(
        outside_root,
        "CabinTable",
        Vector3(14.0, 0.72, -80.2),
        Vector3(2.2, 0.16, 1.0),
        material
    )

    if generator_script != null:
        shelter_generator = StaticBody3D.new()
        shelter_generator.name = "ShelterGenerator"
        shelter_generator.set_script(generator_script)
        shelter_generator.position = Vector3(18.25, 0.0, -84.75)
        outside_root.add_child(shelter_generator)

    var interior_light: OmniLight3D = OmniLight3D.new()
    interior_light.name = "ShelterInteriorLight"
    interior_light.position = Vector3(14.0, 2.85, -82.0)
    interior_light.light_color = Color(0.82, 0.76, 0.58, 1.0)
    interior_light.light_energy = 0.0
    interior_light.omni_range = 10.5
    interior_light.shadow_enabled = true
    outside_root.add_child(interior_light)
    shelter_lights.append(interior_light)

    var porch_light: OmniLight3D = OmniLight3D.new()
    porch_light.name = "ShelterPorchLight"
    porch_light.position = Vector3(14.0, 2.75, -88.0)
    porch_light.light_color = Color(0.76, 0.72, 0.58, 1.0)
    porch_light.light_energy = 0.0
    porch_light.omni_range = 10.0
    porch_light.shadow_enabled = true
    outside_root.add_child(porch_light)
    shelter_lights.append(porch_light)

func _ensure_v183_forest_polish(scene: Node) -> void:
    super._ensure_v183_forest_polish(scene)
    if outside_root == null or not is_instance_valid(outside_root):
        return

    var step: CSGBox3D = outside_root.get_node_or_null("CabinEntryStepV183") as CSGBox3D
    if step != null:
        step.position = Vector3(14.0, 0.055, -87.85)
        step.size = Vector3(3.1, 0.11, 1.15)

    var entry_light: OmniLight3D = outside_root.get_node_or_null("CabinEntryDimV183") as OmniLight3D
    if entry_light != null:
        entry_light.position = Vector3(14.0, 2.45, -87.65)
        entry_light.omni_range = 5.8
