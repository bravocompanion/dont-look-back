extends Node

var configured_scene_id: int = 0
var relay_script: Script
var finish_script: Script
var expansion_root: Node3D
var relay_lights: Dictionary = {}
var active_relays: Dictionary = {}
var power_gate: StaticBody3D
var final_beacon: OmniLight3D
var checkpoint_registered: bool = false
var intro_announced: bool = false

const CHECKPOINT_POSITION := Vector3(-7.0, 0.92, -34.4)

func _ready() -> void:
    relay_script = load("res://scripts/light_relay.gd") as Script
    finish_script = load("res://scripts/finish_trigger.gd") as Script

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        expansion_root = null
        relay_lights.clear()
        power_gate = null
        final_beacon = null
        checkpoint_registered = false
        intro_announced = false
        call_deferred("_configure_scene", scene)
        return

    if expansion_root == null or not is_instance_valid(expansion_root):
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    if not intro_announced and player.global_position.z < -15.2:
        intro_announced = true
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if objective != null:
            objective.text = "LABYRINTH: Restore all 3 emergency relays. Light keeps the dark away."

    if not checkpoint_registered and player.global_position.distance_to(CHECKPOINT_POSITION) <= 2.0:
        _activate_checkpoint(player)

func activate_relay(relay_id: int) -> bool:
    if relay_id < 0 or relay_id > 2:
        return false
    if bool(active_relays.get(relay_id, false)):
        return false

    active_relays[relay_id] = true
    _apply_relay_light(relay_id, true)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if objective != null:
            var count: int = _active_relay_count()
            if count >= 3:
                objective.text = "All emergency relays are online. The final gate has opened."
            else:
                objective.text = "Emergency power restored: %d / 3 relays." % count

    _update_gate_state()
    return true

func _configure_scene(scene: Node) -> void:
    if not is_instance_valid(scene):
        return

    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    var old_end: Node = scene.get_node_or_null("EndWall")
    if old_end != null:
        old_end.free()

    var old_finish: Node = scene.get_node_or_null("FinishTrigger")
    if old_finish != null:
        old_finish.free()

    expansion_root = Node3D.new()
    expansion_root.name = "LabyrinthExpansion"
    scene.add_child(expansion_root)

    var wall_material: StandardMaterial3D = StandardMaterial3D.new()
    wall_material.albedo_color = Color(0.105, 0.11, 0.12, 1.0)
    wall_material.roughness = 0.96

    var floor_material: StandardMaterial3D = StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.035, 0.04, 0.045, 1.0)
    floor_material.roughness = 0.86

    _add_csg_box(expansion_root, "MazeFloor", Vector3(0.0, -0.1, -33.0), Vector3(20.0, 0.2, 36.0), floor_material)
    _add_csg_box(expansion_root, "MazeCeiling", Vector3(0.0, 3.1, -33.0), Vector3(20.0, 0.2, 36.0), wall_material)

    _add_csg_box(expansion_root, "PerimeterLeft", Vector3(-10.0, 1.5, -33.0), Vector3(0.2, 3.2, 36.0), wall_material)
    _add_csg_box(expansion_root, "PerimeterRight", Vector3(10.0, 1.5, -33.0), Vector3(0.2, 3.2, 36.0), wall_material)
    _add_csg_box(expansion_root, "PerimeterBack", Vector3(0.0, 1.5, -51.0), Vector3(20.0, 3.2, 0.2), wall_material)
    _add_csg_box(expansion_root, "FrontLeft", Vector3(-6.1, 1.5, -15.0), Vector3(7.8, 3.2, 0.2), wall_material)
    _add_csg_box(expansion_root, "FrontRight", Vector3(6.1, 1.5, -15.0), Vector3(7.8, 3.2, 0.2), wall_material)

    _add_csg_box(expansion_root, "MazeWallA", Vector3(-3.0, 1.5, -21.0), Vector3(14.0, 3.2, 0.24), wall_material)
    _add_csg_box(expansion_root, "MazeWallB", Vector3(3.0, 1.5, -30.0), Vector3(14.0, 3.2, 0.24), wall_material)
    _add_csg_box(expansion_root, "MazeWallC", Vector3(-3.0, 1.5, -39.0), Vector3(14.0, 3.2, 0.24), wall_material)
    _add_csg_box(expansion_root, "MazeWallD", Vector3(3.0, 1.5, -47.0), Vector3(14.0, 3.2, 0.24), wall_material)

    _add_csg_box(expansion_root, "DeadEndWall1", Vector3(3.2, 1.5, -25.4), Vector3(0.24, 3.2, 5.0), wall_material)
    _add_csg_box(expansion_root, "DeadEndWall2", Vector3(-3.2, 1.5, -34.5), Vector3(0.24, 3.2, 4.6), wall_material)

    _add_dim_light(expansion_root, Vector3(0.0, 2.7, -18.0))
    _add_dim_light(expansion_root, Vector3(7.0, 2.7, -25.0))
    _add_dim_light(expansion_root, Vector3(-7.0, 2.7, -34.0))
    _add_dim_light(expansion_root, Vector3(7.0, 2.7, -43.0))

    _spawn_relay(expansion_root, 0, Vector3(7.4, 0.0, -25.4), "Relay A")
    _spawn_relay(expansion_root, 1, Vector3(-7.4, 0.0, -34.4), "Relay B")
    _spawn_relay(expansion_root, 2, Vector3(7.4, 0.0, -43.4), "Relay C")

    _create_checkpoint_beacon(expansion_root)
    _create_power_gate(expansion_root)
    _create_final_exit(expansion_root)

    for relay_id: int in range(3):
        _apply_relay_light(relay_id, bool(active_relays.get(relay_id, false)))

    _restore_relay_visuals()
    _update_gate_state()

func _spawn_relay(parent: Node3D, relay_id: int, position: Vector3, relay_name: String) -> void:
    if relay_script == null:
        return

    var relay: StaticBody3D = StaticBody3D.new()
    relay.name = "EmergencyRelay%d" % (relay_id + 1)
    relay.set_script(relay_script)
    relay.set("relay_id", relay_id)
    relay.set("relay_name", relay_name)
    relay.position = position
    parent.add_child(relay)

    var light: OmniLight3D = OmniLight3D.new()
    light.name = "RelayLight%d" % (relay_id + 1)
    light.position = position + Vector3(0.0, 2.45, 0.0)
    light.light_color = Color(0.72, 0.80, 0.64, 1.0)
    light.light_energy = 0.0
    light.omni_range = 7.0
    light.shadow_enabled = true
    parent.add_child(light)
    relay_lights[relay_id] = light

func _create_checkpoint_beacon(parent: Node3D) -> void:
    var pillar_material: StandardMaterial3D = StandardMaterial3D.new()
    pillar_material.albedo_color = Color(0.17, 0.23, 0.20, 1.0)
    pillar_material.metallic = 0.35
    pillar_material.roughness = 0.52

    _add_csg_box(parent, "CheckpointPillar", Vector3(-7.0, 0.65, -34.4), Vector3(0.55, 1.3, 0.55), pillar_material)

    var light: OmniLight3D = OmniLight3D.new()
    light.name = "CheckpointLight"
    light.position = Vector3(-7.0, 2.35, -34.4)
    light.light_color = Color(0.58, 0.82, 0.68, 1.0)
    light.light_energy = 1.0
    light.omni_range = 4.2
    light.shadow_enabled = true
    parent.add_child(light)

func _create_power_gate(parent: Node3D) -> void:
    power_gate = StaticBody3D.new()
    power_gate.name = "PowerGate"
    power_gate.position = Vector3(-7.0, 1.5, -47.0)
    parent.add_child(power_gate)

    var gate_mesh: BoxMesh = BoxMesh.new()
    gate_mesh.size = Vector3(6.0, 3.0, 0.28)
    var gate_material: StandardMaterial3D = StandardMaterial3D.new()
    gate_material.albedo_color = Color(0.16, 0.08, 0.07, 1.0)
    gate_material.metallic = 0.52
    gate_material.roughness = 0.48

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.mesh = gate_mesh
    mesh_instance.material_override = gate_material
    power_gate.add_child(mesh_instance)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(6.0, 3.0, 0.28)
    collision.shape = shape
    power_gate.add_child(collision)

    final_beacon = OmniLight3D.new()
    final_beacon.name = "FinalBeacon"
    final_beacon.position = Vector3(-7.0, 2.45, -49.0)
    final_beacon.light_color = Color(0.72, 0.88, 0.72, 1.0)
    final_beacon.light_energy = 0.0
    final_beacon.omni_range = 6.0
    final_beacon.shadow_enabled = true
    parent.add_child(final_beacon)

func _create_final_exit(parent: Node3D) -> void:
    if finish_script == null:
        return

    var finish: Area3D = Area3D.new()
    finish.name = "ExpandedFinishTrigger"
    finish.position = Vector3(-7.0, 1.2, -49.6)
    finish.set_script(finish_script)
    finish.set("end_panel_path", NodePath("../../Player/HUD/EndPanel"))
    parent.add_child(finish)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(5.2, 2.5, 1.0)
    collision.shape = shape
    finish.add_child(collision)

func _activate_checkpoint(player: CharacterBody3D) -> void:
    checkpoint_registered = true
    var checkpoint_system: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint_system != null and checkpoint_system.has_method("save_checkpoint"):
        checkpoint_system.call("save_checkpoint", player, CHECKPOINT_POSITION, "Labyrinth emergency beacon")

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "CHECKPOINT SAVED — Emergency beacon. Continue restoring relay power."

func _apply_relay_light(relay_id: int, enabled: bool) -> void:
    var light_variant: Variant = relay_lights.get(relay_id)
    if light_variant == null:
        return
    var light: OmniLight3D = light_variant as OmniLight3D
    if light == null:
        return
    light.light_energy = 1.25 if enabled else 0.0

func _restore_relay_visuals() -> void:
    if expansion_root == null:
        return

    for relay_id: int in range(3):
        var relay: Node = expansion_root.get_node_or_null("EmergencyRelay%d" % (relay_id + 1))
        if relay != null and relay.has_method("set_activated_from_restore"):
            relay.call("set_activated_from_restore", bool(active_relays.get(relay_id, false)))

func _update_gate_state() -> void:
    var all_online: bool = _active_relay_count() >= 3
    if final_beacon != null and is_instance_valid(final_beacon):
        final_beacon.light_energy = 1.55 if all_online else 0.0

    if all_online and power_gate != null and is_instance_valid(power_gate):
        power_gate.queue_free()
        power_gate = null

func _active_relay_count() -> int:
    var count: int = 0
    for relay_id: int in range(3):
        if bool(active_relays.get(relay_id, false)):
            count += 1
    return count

func _add_dim_light(parent: Node3D, position: Vector3) -> void:
    var light: OmniLight3D = OmniLight3D.new()
    light.position = position
    light.light_color = Color(0.42, 0.46, 0.50, 1.0)
    light.light_energy = 0.075
    light.omni_range = 4.5
    parent.add_child(light)

func _add_csg_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> CSGBox3D:
    var box: CSGBox3D = CSGBox3D.new()
    box.name = node_name
    box.position = position
    box.size = size
    box.use_collision = true
    box.material = material
    parent.add_child(box)
    return box
