extends "res://scripts/flashlight_motion_system.gd"

# Lower the first-person beam origin by 20% of the ranger camera height.
# Camera3D sits at Y=0.58 in the active player scenes, so the drop is 0.116 m.
const V40_CAMERA_HEIGHT_REFERENCE: float = 0.58
const V40_LOWER_PLACEMENT_RATIO: float = 0.20
const V40_VERTICAL_DROP: float = V40_CAMERA_HEIGHT_REFERENCE * V40_LOWER_PLACEMENT_RATIO

func _ensure_player() -> bool:
    var player_ready: bool = super._ensure_player()
    if not player_ready or flashlight == null:
        return false

    # Metadata prevents a second 20% drop if this same flashlight node is
    # temporarily released/rebound by another runtime system.
    if not bool(flashlight.get_meta("v40_lowered", false)):
        base_position.y -= V40_VERTICAL_DROP
        flashlight.position = base_position
        flashlight.set_meta("v40_lowered", true)
    else:
        base_position = flashlight.position - smoothed_position_offset

    return true
