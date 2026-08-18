extends "res://scripts/shelter_system.gd"

const FIXED_BED_SCRIPT_PATH: String = "res://scripts/shelter_bed_fixed.gd"
const CAMPFIRE_POSITION_V31: Vector3 = Vector3(9.8, 0.0, -91.4)
const WORKBENCH_POSITION_V31: Vector3 = Vector3(18.15, 0.0, -78.4)
const CHEST_POSITION_V31: Vector3 = Vector3(18.55, 0.0, -82.0)
const BED_POSITION_V31: Vector3 = Vector3(9.45, 0.0, -80.2)

func _ready() -> void:
    super._ready()
    bed_script = load(FIXED_BED_SCRIPT_PATH) as Script

func _attach_shelter_objects() -> void:
    # Let the base system create/synchronize all gameplay objects, then apply
    # the v0.31 layout. This preserves storage, crafting and sleep behavior.
    super._attach_shelter_objects()
    if outside_root == null:
        return

    shelter_generator = outside_root.get_node_or_null("ShelterGenerator") as StaticBody3D
    if shelter_generator != null:
        shelter_generator.position = Vector3(18.25, 0.0, -84.75)
        shelter_generator.rotation.y = 0.0

    var workbench: StaticBody3D = outside_root.get_node_or_null("ShelterWorkbench") as StaticBody3D
    if workbench != null:
        workbench.position = WORKBENCH_POSITION_V31
        workbench.rotation.y = 0.0

    var chest: StaticBody3D = outside_root.get_node_or_null("ShelterChest") as StaticBody3D
    if chest != null:
        chest.position = CHEST_POSITION_V31
        chest.rotation.y = PI * 0.5

    var bed: StaticBody3D = outside_root.get_node_or_null("ShelterBed") as StaticBody3D
    if bed != null:
        bed.position = BED_POSITION_V31
        bed.rotation.y = 0.0

    # Fire stays outside the wooden cabin, to the left of the porch, leaving a
    # clear straight path between the 3 m door opening and the ranger gate.
    var campfire: StaticBody3D = outside_root.get_node_or_null("ShelterCampfire") as StaticBody3D
    if campfire != null:
        campfire.position = CAMPFIRE_POSITION_V31

    campfire_light = outside_root.get_node_or_null("CampfireLight") as OmniLight3D
    if campfire_light != null:
        campfire_light.position = CAMPFIRE_POSITION_V31 + Vector3(0.0, 1.0, 0.0)
