extends "res://scripts/outside_director_v181.gd"

const RANGER_DEPLOYMENT_SPAWN: Vector3 = Vector3(14.0, 0.92, -90.0)

func enter_outside(player: CharacterBody3D) -> void:
    super.enter_outside(player)
    if player == null:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return
    player.global_position = RANGER_DEPLOYMENT_SPAWN
    player.rotation.y = 0.0
    player.velocity = Vector3.ZERO
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "RANGER DEPLOYMENT: Cabin di belakangmu. Hadapi hutan, amankan shelter, lalu mulai investigasi."

## Mirror the original cabin frontage. The door/porch is now on the -Z side,
## which faces the deep forest and mission route instead of the map edge.
func _build_cabin(material: Material) -> void:
    if outside_root == null:
        return

    _add_csg_box(outside_root, "CabinFloor", Vector3(14.0, 0.08, -82.0), Vector3(8.0, 0.18, 7.0), material)
    _add_csg_box(outside_root, "CabinRoof", Vector3(14.0, 3.15, -82.0), Vector3(8.4, 0.28, 7.4), material)
    _add_csg_box(outside_root, "CabinLeft", Vector3(10.0, 1.55, -82.0), Vector3(0.22, 3.0, 7.0), material)
    _add_csg_box(outside_root, "CabinRight", Vector3(18.0, 1.55, -82.0), Vector3(0.22, 3.0, 7.0), material)

    # Solid wall now faces the outer/map-edge side.
    _add_csg_box(outside_root, "CabinBack", Vector3(14.0, 1.55, -78.5), Vector3(8.0, 3.0, 0.22), material)
    # Door opening now faces the deep forest (-Z).
    _add_csg_box(outside_root, "CabinFrontLeft", Vector3(11.4, 1.55, -85.5), Vector3(2.8, 3.0, 0.22), material)
    _add_csg_box(outside_root, "CabinFrontRight", Vector3(16.6, 1.55, -85.5), Vector3(2.8, 3.0, 0.22), material)
    _add_csg_box(outside_root, "CabinTable", Vector3(12.0, 0.72, -83.7), Vector3(1.8, 0.16, 0.8), material)

    if generator_script != null:
        shelter_generator = StaticBody3D.new()
        shelter_generator.name = "ShelterGenerator"
        shelter_generator.set_script(generator_script)
        shelter_generator.position = Vector3(16.1, 0.0, -84.0)
        outside_root.add_child(shelter_generator)

    var interior_light: OmniLight3D = OmniLight3D.new()
    interior_light.name = "ShelterInteriorLight"
    interior_light.position = Vector3(14.0, 2.45, -82.0)
    interior_light.light_color = Color(0.82, 0.76, 0.58, 1.0)
    interior_light.light_energy = 0.0
    interior_light.omni_range = 7.2
    interior_light.shadow_enabled = true
    outside_root.add_child(interior_light)
    shelter_lights.append(interior_light)

    var porch_light: OmniLight3D = OmniLight3D.new()
    porch_light.name = "ShelterPorchLight"
    porch_light.position = Vector3(14.0, 2.55, -86.2)
    porch_light.light_color = Color(0.76, 0.72, 0.58, 1.0)
    porch_light.light_energy = 0.0
    porch_light.omni_range = 8.0
    porch_light.shadow_enabled = true
    outside_root.add_child(porch_light)
    shelter_lights.append(porch_light)

func _ensure_v183_forest_polish(scene: Node) -> void:
    super._ensure_v183_forest_polish(scene)
    if outside_root == null or not is_instance_valid(outside_root):
        return
    var step: CSGBox3D = outside_root.get_node_or_null("CabinEntryStepV183") as CSGBox3D
    if step != null:
        step.position = Vector3(14.0, 0.055, -86.05)
    var entry_light: OmniLight3D = outside_root.get_node_or_null("CabinEntryDimV183") as OmniLight3D
    if entry_light != null:
        entry_light.position = Vector3(14.0, 2.25, -85.85)
