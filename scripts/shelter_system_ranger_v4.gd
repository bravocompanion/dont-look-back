extends "res://scripts/shelter_system_ranger_v3.gd"

const ICON_STASH_SCRIPT_PATH: String = "res://scripts/shelter_chest_v42.gd"

func _ready() -> void:
    super._ready()
    chest_script = load(ICON_STASH_SCRIPT_PATH) as Script
