extends "res://scripts/survival_system_ranger_v2.gd"

# v0.68 keeps the v0.65 Forest/wildlife runtime while upgrading Inventory to
# coexist cleanly with the new progression overlay.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v57.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v65.gd")

func get_survival_progression_contract_v68() -> Dictionary:
    return {
        "inventory_menu": "res://scripts/inventory_menu_system_v57.gd",
        "forest_runtime": "res://scripts/forest_survival_system_v65.gd",
        "progression_menu_exclusive": true,
        "weight_system_retained": true,
        "wildlife_stability_retained": true
    }
