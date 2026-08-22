extends "res://scripts/forest_survival_system_v52.gd"

const WILDLIFE_V53_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v53.gd"

# Requested v0.53 draw sway tiers relative to the original stationary sway:
# stationary 150%, walking 200%, sprinting 350%.
@export var bow_idle_sway_bonus_v53: float = 0.50
@export var bow_walk_sway_bonus_v53: float = 1.00
@export var bow_run_sway_bonus_v53: float = 2.50

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V53_SCRIPT_PATH) as Script

    # v0.52 owns the single smooth sway implementation; v0.53 only changes
    # its mutually-exclusive amplitude tiers so no extra oscillator is added.
    bow_idle_sway_bonus_v52 = bow_idle_sway_bonus_v53
    bow_walk_sway_bonus_v52 = bow_walk_sway_bonus_v53
    bow_run_sway_bonus_v52 = bow_run_sway_bonus_v53
