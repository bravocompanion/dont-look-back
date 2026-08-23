extends "res://scripts/survival_system_ranger_v2.gd"

func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    _attach_runtime("InventoryMenuRuntime", "res://scripts/inventory_menu_system_v58.gd")
    _attach_runtime("PanicMovementTuningRuntime", "res://scripts/panic_movement_tuning_system.gd")
    _attach_runtime("NarrativeLoreRuntime", "res://scripts/narrative_lore_system.gd")
    _attach_runtime("ForestSurvivalRuntime", "res://scripts/forest_survival_system_v66.gd")

func get_survival_ui_collision_contract_v71() -> Dictionary:
    return {
        "inventory_menu": "res://scripts/inventory_menu_system_v58.gd",
        "forest_runtime": "res://scripts/forest_survival_system_v66.gd",
        "central_gameplay_lock": true,
        "weight_system_retained": true,
        "progression_milestones_retained": true,
        "wildlife_stability_retained": true
    }
