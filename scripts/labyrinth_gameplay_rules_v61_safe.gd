extends "res://scripts/labyrinth_gameplay_rules_v61.gd"

func _update_runtime_visibility_v61(stage: int) -> void:
    super._update_runtime_visibility_v61(stage)
    for value: Variant in stabilizer_nodes.values():
        var body: StaticBody3D = value as StaticBody3D
        if body == null or not is_instance_valid(body):
            continue
        body.collision_layer = 1 if stage == 3 else 0
        body.collision_mask = 1 if stage == 3 else 0

func _refresh_visuals_v61() -> void:
    super._refresh_visuals_v61()
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    var lockdown_enabled: bool = arc != null and int(arc.get("current_stage")) == 5 and bool(arc.get("holdout_active"))
    if lockdown_enabled:
        return
    for light: OmniLight3D in beacon_lights:
        if light != null and is_instance_valid(light):
            light.light_energy = 0.0
