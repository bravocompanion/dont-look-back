extends "res://scripts/shelter_bed.gd"

## Ranger cabin layout owns the bed position explicitly. The legacy bed added
## +2.3 m on X during _ready(), which made editor/runtime positions disagree.
func _ready() -> void:
    _build_visual()
