extends "res://scripts/survival_system_ranger_v2.gd"

# v0.65 keeps all v0.64 wildlife stability and v0.55 Ranger survival economy,
# while activating the front-left cabin work-area layout.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v55.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v65.gd")
