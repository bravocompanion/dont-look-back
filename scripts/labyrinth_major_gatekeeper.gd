extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const COVER_SCRIPT_PATH: String = "res://scripts/arc1_lockdown_cover.gd"

var cover_script: Script
var cover: StaticBody3D
var configured_scene_id: int = 0
var hud_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    cover_script = load(COVER_SCRIPT_PATH) as Script

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        cover = null
        configured_scene_id = 0
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if arc_root == null or arc == null or major == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        cover = null

    _update_lockdown_cover(arc_root, arc, major)
    _balance_warden_pressure(arc, major)

    hud_timer -= delta
    if hud_timer <= 0.0:
        hud_timer = 0.22
        _update_major_hud(arc, major)

func _update_lockdown_cover(arc_root: Node3D, arc: Node, major: Node) -> void:
    var stage: int = int(arc.get("current_stage"))
    var holdout: bool = bool(arc.get("holdout_active"))
    var ready: bool = major.has_method("is_lockdown_ready") and bool(major.call("is_lockdown_ready"))
    var should_block: bool = stage == 4 and not holdout and not ready

    if should_block:
        if cover == null or not is_instance_valid(cover):
            _spawn_cover(arc_root)
        return

    if cover != null and is_instance_valid(cover):
        cover.queue_free()
    cover = null

func _spawn_cover(arc_root: Node3D) -> void:
    if cover_script == null:
        return
    var old: Node = arc_root.get_node_or_null("MajorLockdownInterlock")
    if old != null:
        old.queue_free()
    cover = StaticBody3D.new()
    cover.name = "MajorLockdownInterlock"
    cover.position = Vector3(0.0, 0.0, -135.08)
    cover.set_script(cover_script)
    arc_root.add_child(cover)

func _balance_warden_pressure(arc: Node, major: Node) -> void:
    if not major.has_method("is_warden_active") or not bool(major.call("is_warden_active")):
        return
    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director == null:
        return

    var active_value: Variant = director.get("active_enemy_ids")
    if not (active_value is Array):
        return
    var max_arc_enemies: int = 2 if bool(arc.get("holdout_active")) else 1
    var active_ids: Array = Array(active_value)
    if active_ids.size() <= max_arc_enemies:
        return

    var trimmed: Array[String] = []
    for index: int in range(mini(max_arc_enemies, active_ids.size())):
        trimmed.append(str(active_ids[index]))
    director.set("active_enemy_ids", trimmed)
    director.set("threat_budget", mini(int(director.get("threat_budget")), max_arc_enemies))

func _update_major_hud(arc: Node, major: Node) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or player.global_position.z > -48.0:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective == null:
        return

    var stage: int = int(arc.get("current_stage"))
    if stage == 4 and major.has_method("is_lockdown_ready") and not bool(major.call("is_lockdown_ready")):
        var count: int = int(major.call("get_isolation_completed_count")) if major.has_method("get_isolation_completed_count") else 0
        var variant: int = int(major.call("get_route_variant")) if major.has_method("get_route_variant") else 0
        objective.text = "ARC 1 — ISOLATION SWEEP: shut down M/F/A nodes %d / 3. Route mutation %d. The Warden is active." % [count, variant + 1]
        return

    if bool(arc.get("holdout_active")) and major.has_method("get_finale_phase"):
        var phase: int = maxi(1, int(major.call("get_finale_phase")))
        var remaining: int = maxi(0, int(ceil(float(arc.get("holdout_remaining")))))
        objective.text = "LOCKDOWN PHASE %d / 3 — %d:%02d. Keep moving; emergency routes are unstable." % [phase, remaining / 60, remaining % 60]
