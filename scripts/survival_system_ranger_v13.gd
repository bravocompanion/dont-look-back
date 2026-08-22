extends "res://scripts/survival_system_ranger_v2.gd"

# v0.64 keeps the v0.55 Ranger survival stack while swapping only the Forest
# runtime to the wildlife flee/embedded-arrow stability pass.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v55.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v64.gd")
