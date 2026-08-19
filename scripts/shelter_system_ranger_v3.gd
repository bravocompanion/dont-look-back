extends "res://scripts/shelter_system_ranger_v2.gd"

const EXPANDED_WORKBENCH_SCRIPT_PATH: String = "res://scripts/shelter_workbench_v41.gd"

func _ready() -> void:
    super._ready()
    workbench_script = load(EXPANDED_WORKBENCH_SCRIPT_PATH) as Script
