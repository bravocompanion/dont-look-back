extends "res://scripts/outside_director_ranger_v4.gd"

const RANGER_START_MINUTES_V40: float = 360.0

func _ready() -> void:
    super._ready()
    # New ranger runs begin at 06:00. Save restoration may overwrite this later.
    game_minutes = RANGER_START_MINUTES_V40

func _build_cabin(material: Material) -> void:
    super._build_cabin(material)
    if outside_root == null:
        return

    # Lower the cabin floor so the doorway threshold no longer behaves like a
    # step that requires jumping. The top surface is now about 8 cm above grade.
    var floor: CSGBox3D = outside_root.get_node_or_null("CabinFloor") as CSGBox3D
    if floor != null:
        floor.position.y = 0.04
        floor.size.y = 0.08

func _ensure_v183_forest_polish(scene: Node) -> void:
    super._ensure_v183_forest_polish(scene)
    if outside_root == null or not is_instance_valid(outside_root):
        return

    # Disable the old box step and replace it with a shallow physical ramp.
    # The ramp rises from ground level to the lowered cabin floor, so normal
    # walking works on desktop and mobile without changing world-wide step rules.
    var old_step: CSGBox3D = outside_root.get_node_or_null("CabinEntryStepV183") as CSGBox3D
    if old_step != null:
        old_step.use_collision = false
        old_step.visible = false

    var ramp: CSGBox3D = outside_root.get_node_or_null("CabinEntryRampV40") as CSGBox3D
    if ramp == null:
        ramp = CSGBox3D.new()
        ramp.name = "CabinEntryRampV40"
        ramp.position = Vector3(14.0, 0.0, -88.10)
        ramp.size = Vector3(3.20, 0.08, 1.70)
        ramp.rotation_degrees = Vector3(-2.7, 0.0, 0.0)
        ramp.use_collision = true
        var floor: CSGBox3D = outside_root.get_node_or_null("CabinFloor") as CSGBox3D
        if floor != null:
            ramp.material = floor.material
        outside_root.add_child(ramp)
