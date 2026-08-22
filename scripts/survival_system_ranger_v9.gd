extends "res://scripts/survival_system_ranger_v2.gd"

# v0.52: ranger-first runtime with anti-orbit wounded wildlife, harvestable
# lying corpses, stronger smooth bow sway, and all v0.51 Tenant/night rules.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v43.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v52.gd")
