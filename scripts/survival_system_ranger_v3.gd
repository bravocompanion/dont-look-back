extends "res://scripts/survival_system_ranger_v2.gd"

# v0.45: keep the ranger-first scene isolation from v2, but attach the new
# hold-to-draw Forest hunting runtime instead of the v0.44 fixed-power bow.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v43.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v45.gd")
