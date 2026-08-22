extends "res://scripts/outside_director_ranger_v6.gd"

# v0.65: a running generator should read as real shelter power, not a dim glow.
# Keep only the authored cabin/porch lights shadow-casting; two visual fill lights
# are shadowless and explicitly non-protective to stay cheap on Android/Web and
# to avoid silently expanding the gameplay safe-light radius.
const CABIN_LIGHT_ENERGY_V65: float = 3.35
const CABIN_LIGHT_RANGE_V65: float = 13.5
const PORCH_LIGHT_ENERGY_V65: float = 3.10
const PORCH_LIGHT_RANGE_V65: float = 16.0
const YARD_FILL_ENERGY_V65: float = 2.35
const YARD_FILL_RANGE_V65: float = 18.5
const WORK_FILL_ENERGY_V65: float = 1.90
const WORK_FILL_RANGE_V65: float = 15.5

var yard_fill_v65: OmniLight3D
var work_fill_v65: OmniLight3D

func _build_cabin(material: Material) -> void:
    super._build_cabin(material)
    if outside_root == null:
        return

    yard_fill_v65 = _ensure_generator_fill_v65(
        "GeneratorYardFillV65",
        Vector3(14.0, 3.25, -91.0),
        Color(1.0, 0.82, 0.58, 1.0),
        YARD_FILL_RANGE_V65
    )
    work_fill_v65 = _ensure_generator_fill_v65(
        "GeneratorWorkAreaFillV65",
        Vector3(10.8, 2.6, -90.7),
        Color(1.0, 0.72, 0.43, 1.0),
        WORK_FILL_RANGE_V65
    )

    # Let the existing power path own on/off state, including save restore and
    # multiplayer shelter sync. The override below then applies v0.65 levels.
    _apply_shelter_power()

func _apply_shelter_power() -> void:
    super._apply_shelter_power()
    if outside_root == null:
        return

    var interior: OmniLight3D = outside_root.get_node_or_null("ShelterInteriorLight") as OmniLight3D
    if interior != null:
        interior.omni_range = CABIN_LIGHT_RANGE_V65
        interior.light_energy = CABIN_LIGHT_ENERGY_V65 if shelter_powered else 0.0
        interior.shadow_enabled = true

    var porch: OmniLight3D = outside_root.get_node_or_null("ShelterPorchLight") as OmniLight3D
    if porch != null:
        porch.omni_range = PORCH_LIGHT_RANGE_V65
        porch.light_energy = PORCH_LIGHT_ENERGY_V65 if shelter_powered else 0.0
        porch.shadow_enabled = true

    yard_fill_v65 = outside_root.get_node_or_null("GeneratorYardFillV65") as OmniLight3D
    if yard_fill_v65 != null:
        yard_fill_v65.light_energy = YARD_FILL_ENERGY_V65 if shelter_powered else 0.0

    work_fill_v65 = outside_root.get_node_or_null("GeneratorWorkAreaFillV65") as OmniLight3D
    if work_fill_v65 != null:
        work_fill_v65.light_energy = WORK_FILL_ENERGY_V65 if shelter_powered else 0.0

func _ensure_generator_fill_v65(node_name: String, world_position: Vector3, color: Color, range_value: float) -> OmniLight3D:
    var light: OmniLight3D = outside_root.get_node_or_null(NodePath(node_name)) as OmniLight3D
    if light == null:
        light = OmniLight3D.new()
        light.name = StringName(node_name)
        outside_root.add_child(light)
    light.position = world_position
    light.light_color = color
    light.light_energy = 0.0
    light.omni_range = range_value
    light.shadow_enabled = false
    light.add_to_group("non_protective_light")
    light.set_meta("non_protective_light_v63", true)
    return light

func get_generator_lighting_contract_v65() -> Dictionary:
    return {
        "cabin_energy": CABIN_LIGHT_ENERGY_V65,
        "cabin_range": CABIN_LIGHT_RANGE_V65,
        "porch_energy": PORCH_LIGHT_ENERGY_V65,
        "porch_range": PORCH_LIGHT_RANGE_V65,
        "yard_fill_energy": YARD_FILL_ENERGY_V65,
        "yard_fill_range": YARD_FILL_RANGE_V65,
        "work_fill_energy": WORK_FILL_ENERGY_V65,
        "work_fill_range": WORK_FILL_RANGE_V65,
        "shadowed_primary_lights": 2,
        "shadowless_fill_lights": 2,
        "fill_lights_expand_protection": false
    }
