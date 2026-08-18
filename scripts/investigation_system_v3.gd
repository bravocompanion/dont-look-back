extends "res://scripts/investigation_system_v2.gd"

func _configure_forest(scene: Node) -> void:
    super._configure_forest(scene)

    # Cabin back wall moved to Z=-76.75 in v0.31. Keep the case board mounted
    # on that wall instead of floating in the middle of the enlarged room.
    var case_board: Node3D = scene.get_node_or_null("RangerCaseBoard") as Node3D
    if case_board != null:
        case_board.position = Vector3(14.0, 1.45, -77.05)
