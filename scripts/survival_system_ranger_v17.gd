extends "res://scripts/survival_system_ranger_v2.gd"

# v0.69 keeps the v0.68 inventory/progression overlay contract and swaps only
# the Forest runtime to the milestone-aware v66 bridge.
func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v57.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v66.gd")

func get_survival_progression_contract_v69() -> Dictionary:
    return {
        "inventory_menu": "res://scripts/inventory_menu_system_v57.gd",
        "forest_runtime": "res://scripts/forest_survival_system_v66.gd",
        "first_harvest_milestone": true,
        "first_fishing_milestone": true,
        "progression_menu_exclusive": true,
        "weight_system_retained": true,
        "wildlife_stability_retained": true
    }
