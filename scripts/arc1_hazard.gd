extends Node3D

@export var hazard_id: String = "steam_vent"
@export var hazard_kind: String = "steam"
@export var activation_stage: int = 2
@export var hazard_radius: float = 1.4
@export var damage: float = 9.0
@export var cycle_duration: float = 5.0
@export var active_duration: float = 1.1
@export var phase_offset: float = 0.0
@export var hit_cooldown: float = 1.25

var dangerous: bool = false
var was_dangerous: bool = false
var damage_timer: float = 0.0
var visual_material: StandardMaterial3D
var warning_light: OmniLight3D
var active_visual: MeshInstance3D

func _ready() -> void:
    _build_visual()

func _process(delta: float) -> void:
    damage_timer = maxf(0.0, damage_timer - delta)

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        visible = false
        return

    var stage: int = int(arc.get("current_stage"))
    var enabled: bool = stage >= activation_stage and stage < 6
    visible = enabled
    if not enabled:
        dangerous = false
        was_dangerous = false
        _update_visual(false)
        return

    var shared_time: float = float(Time.get_ticks_msec()) / 1000.0
    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director != null and director.has_method("get_shared_time"):
        shared_time = float(director.call("get_shared_time"))

    var safe_cycle: float = maxf(0.5, cycle_duration)
    var phase: float = fmod(shared_time + phase_offset, safe_cycle)
    dangerous = phase <= active_duration
    _update_visual(dangerous)

    if dangerous and not was_dangerous:
        _report_noise()
    was_dangerous = dangerous

    if dangerous and damage_timer <= 0.0 and _is_authoritative():
        if _damage_survivors():
            damage_timer = hit_cooldown

func _damage_survivors() -> bool:
    var hit_any: bool = false
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))

    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
            return false
        var ids_value: Variant = coop.call("_get_active_peer_ids")
        if not (ids_value is Array):
            return false
        for peer_variant: Variant in Array(ids_value):
            var peer_id: int = int(peer_variant)
            var state_value: Variant = coop.call("_get_survivor_state", peer_id)
            if not (state_value is Dictionary):
                continue
            var state: Dictionary = Dictionary(state_value)
            if bool(state.get("downed", false)):
                continue
            var transform_value: Variant = state.get("transform", null)
            if not (transform_value is Transform3D):
                continue
            var survivor_transform: Transform3D = transform_value
            if _position_is_hazardous(survivor_transform.origin):
                if coop.has_method("damage_survivor"):
                    coop.call("damage_survivor", peer_id, damage, _source_name())
                    hit_any = true
        return hit_any

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null and _position_is_hazardous(player.global_position) and player.has_method("apply_damage"):
        player.call("apply_damage", damage, _source_name())
        hit_any = true
    return hit_any

func _position_is_hazardous(position: Vector3) -> bool:
    var horizontal: float = Vector2(position.x - global_position.x, position.z - global_position.z).length()
    if horizontal > hazard_radius:
        return false
    if hazard_kind == "electric":
        return position.y <= global_position.y + 1.28
    return absf(position.y - global_position.y) <= 2.4

func _source_name() -> String:
    return "Live Current" if hazard_kind == "electric" else "Steam Burst"

func _report_noise() -> void:
    if not _is_authoritative():
        return
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise == null or not noise.has_method("report_noise"):
        return
    var strength: float = 0.42 if hazard_kind == "electric" else 0.68
    noise.call("report_noise", global_position, strength, "%s cycle" % hazard_id)

func _update_visual(is_dangerous: bool) -> void:
    if visual_material == null:
        return

    if hazard_kind == "electric":
        visual_material.albedo_color = Color(0.08, 0.18, 0.23, 1.0) if is_dangerous else Color(0.035, 0.07, 0.08, 1.0)
        visual_material.emission = Color(0.12, 0.55, 0.72, 1.0) if is_dangerous else Color(0.015, 0.04, 0.05, 1.0)
        visual_material.emission_energy_multiplier = 2.2 if is_dangerous else 0.35
    else:
        visual_material.albedo_color = Color(0.56, 0.58, 0.57, 1.0) if is_dangerous else Color(0.13, 0.14, 0.14, 1.0)
        visual_material.emission = Color(0.32, 0.36, 0.34, 1.0) if is_dangerous else Color(0.02, 0.02, 0.02, 1.0)
        visual_material.emission_energy_multiplier = 1.2 if is_dangerous else 0.1

    if warning_light != null:
        warning_light.visible = is_dangerous
    if active_visual != null:
        active_visual.visible = is_dangerous or hazard_kind == "electric"

func _build_visual() -> void:
    visual_material = StandardMaterial3D.new()
    visual_material.roughness = 0.68
    visual_material.emission_enabled = true

    active_visual = MeshInstance3D.new()
    active_visual.name = "HazardVisual"
    active_visual.material_override = visual_material
    add_child(active_visual)

    if hazard_kind == "electric":
        var puddle_mesh: BoxMesh = BoxMesh.new()
        puddle_mesh.size = Vector3(hazard_radius * 1.7, 0.025, hazard_radius * 1.45)
        active_visual.mesh = puddle_mesh
        active_visual.position.y = 0.025
    else:
        var steam_mesh: CylinderMesh = CylinderMesh.new()
        steam_mesh.top_radius = hazard_radius * 0.28
        steam_mesh.bottom_radius = hazard_radius * 0.48
        steam_mesh.height = 2.35
        steam_mesh.radial_segments = 10
        steam_mesh.rings = 2
        active_visual.mesh = steam_mesh
        active_visual.position.y = 1.15

        var pipe_material: StandardMaterial3D = StandardMaterial3D.new()
        pipe_material.albedo_color = Color(0.16, 0.15, 0.14, 1.0)
        pipe_material.metallic = 0.62
        pipe_material.roughness = 0.48
        var pipe_mesh: CylinderMesh = CylinderMesh.new()
        pipe_mesh.top_radius = 0.18
        pipe_mesh.bottom_radius = 0.18
        pipe_mesh.height = 0.48
        pipe_mesh.radial_segments = 10
        var pipe: MeshInstance3D = MeshInstance3D.new()
        pipe.mesh = pipe_mesh
        pipe.material_override = pipe_material
        pipe.position.y = 0.24
        add_child(pipe)

    warning_light = OmniLight3D.new()
    warning_light.name = "HazardWarningLight"
    warning_light.position = Vector3(0.0, 0.55, 0.0)
    warning_light.light_color = Color(0.25, 0.62, 0.72, 1.0) if hazard_kind == "electric" else Color(0.68, 0.56, 0.42, 1.0)
    warning_light.light_energy = 0.085
    warning_light.omni_range = 2.2
    warning_light.shadow_enabled = false
    add_child(warning_light)

    _update_visual(false)

func _is_authoritative() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return true
    return network.has_method("is_server") and bool(network.call("is_server"))
