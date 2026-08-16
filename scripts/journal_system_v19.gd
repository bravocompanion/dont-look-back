extends "res://scripts/journal_system.gd"

func _get_current_mission() -> String:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var outside_active: bool = outside != null and outside.has_method("is_outside_active") and bool(outside.call("is_outside_active"))
    if outside_active:
        return super._get_current_mission()

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return super._get_current_mission()

    var stage: int = int(arc.get("current_stage"))
    var completed: Dictionary = Dictionary(arc.get("completed"))
    var breaker_progress: int = int(arc.get("breaker_progress"))
    var holdout_active: bool = bool(arc.get("holdout_active"))
    var holdout_remaining: float = float(arc.get("holdout_remaining"))

    if stage <= 0:
        return super._get_current_mission()
    if stage == 1:
        return "ARC 1 — Maintenance Wing: restore the three lower-labyrinth fuse boxes (%d / 3)." % _count_arc_ids(completed, ["fuse_a", "fuse_b", "fuse_c"])
    if stage == 2:
        return "ARC 1 — Flooded Service: locate and turn both pressure valves (%d / 2). Supplies are hidden in the side routes." % _count_arc_ids(completed, ["valve_a", "valve_b"])
    if stage == 3:
        return "ARC 1 — Archive: use breaker sequence B → A → C. Current progress %d / 3. Wrong order triggers a blackout alarm." % breaker_progress
    if stage == 4:
        return "ARC 1 — Lockdown: reach the final console. Prepare battery, healing, water and stamina before starting it."
    if stage == 5 or holdout_active:
        var seconds: int = maxi(0, int(ceil(holdout_remaining)))
        return "ARC 1 — Lockdown active: survive stabilization for %d:%02d. Keep moving between lit pockets." % [seconds / 60, seconds % 60]
    return "ARC 1 complete. Follow the final beacon and leave the labyrinth for The Outside."

func _count_arc_ids(values: Dictionary, ids: Array) -> int:
    var count: int = 0
    for id_variant: Variant in ids:
        if bool(values.get(str(id_variant), false)):
            count += 1
    return count
