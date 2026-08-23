extends "res://scripts/survival_system_ranger_v2.gd"

# v0.67 keeps the v0.65 Forest runtime and v0.64 wildlife fixes while swapping
# the inventory menu to the weight-aware presentation.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v56.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v65.gd")

func get_survival_weight_contract_v67() -> Dictionary:
    return {
        "inventory_menu": "res://scripts/inventory_menu_system_v56.gd",
        "forest_runtime": "res://scripts/forest_survival_system_v65.gd",
        "wildlife_stability_retained": true
    }
