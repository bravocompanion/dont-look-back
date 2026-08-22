extends "res://scripts/forest_survival_system_v55.gd"

const WILDLIFE_V64_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v64.gd"
const ARROW_PROJECTILE_V64_SCRIPT_PATH: String = "res://scripts/forest_arrow_projectile_v64.gd"

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V64_SCRIPT_PATH) as Script
    arrow_projectile_script = load(ARROW_PROJECTILE_V64_SCRIPT_PATH) as Script

func get_wildlife_runtime_contract_v64() -> Dictionary:
    return {
        "wildlife_script": WILDLIFE_V64_SCRIPT_PATH,
        "arrow_projectile_script": ARROW_PROJECTILE_V64_SCRIPT_PATH,
        "simulation_owner": "host_or_offline_authority",
        "remote_animals_interpolate_only": true,
        "embedded_arrow_blocks_wildlife": false
    }
