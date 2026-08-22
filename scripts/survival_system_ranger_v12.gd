extends "res://scripts/survival_system_ranger_v2.gd"

# v0.55 ranger-first runtime: v0.54 P0 economy plus P1 renewable-resource,
# fishing/hunting recovery, filter upkeep, and late-game infrastructure rules.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v55.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v55.gd")
