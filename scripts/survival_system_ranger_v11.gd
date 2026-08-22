extends "res://scripts/survival_system_ranger_v2.gd"

# v0.54 ranger-first runtime: v0.53 hunting/sway/wildlife plus P0 survival
# balance changes for carry limits, progression, and renewable-resource pressure.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v54.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v54.gd")
