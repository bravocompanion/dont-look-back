extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@export var send_interval: float = 0.10
@export var tenant_base_move_speed: float = 1.65
@export var tenant_max_move_speed: float = 3.00
@export var tenant_base_attack_cooldown: float = 2.40
@export var tenant_min_attack_cooldown: float = 1.05
@export var tenant_flashlight_dismiss_seconds: float = 3.0

var send_timer: float = 0.0
var peer_panic: Dictionary = {}
var peer_flashlight_contact: Dictionary = {}
var peer_flashlight_hold: Dictionary = {}
var last_tenant_active: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 20
    if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
        multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH or not _network_online():
        _reset_runtime_state()
        return

    var panic_system: Node = get_node_or_null("/root/PanicTenantSystem")
    var local_panic: float = 0.0
    var local_contact: bool = false
    if panic_system != null:
        if panic_system.has_method("get_panic"):
            local_panic = clampf(float(panic_system.call("get_panic")), 0.0, 100.0)
        if panic_system.has_method("is_tenant_in_flashlight"):
            local_contact = bool(panic_system.call("is_tenant_in_flashlight"))

    var local_peer_id: int = multiplayer.get_unique_id()
    if _is_host():
        peer_panic[local_peer_id] = local_panic
        peer_flashlight_contact[local_peer_id] = local_contact
        _drive_host_tenant_state(delta)
    else:
        send_timer -= delta
        if send_timer <= 0.0:
            send_timer = send_interval
            _submit_tenant_motion_state.rpc_id(1, local_panic, local_contact)

@rpc("any_peer", "call_remote", "unreliable", 17)
func _submit_tenant_motion_state(panic: float, flashlight_contact: bool) -> void:
    if not _is_host():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    peer_panic[sender_id] = clampf(panic, 0.0, 100.0)
    peer_flashlight_contact[sender_id] = flashlight_contact

func _drive_host_tenant_state(delta: float) -> void:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return

    # AINavigationSystem owns Tenant movement. Zeroing the old direct-move
    # fields prevents CoopHorrorSystem from moving the same Tenant twice.
    coop.set("tenant_walk_speed", 0.0)
    coop.set("tenant_panic_speed", 0.0)

    var tenant_active: bool = bool(coop.get("tenant_active"))
    if tenant_active and not last_tenant_active:
        _repair_new_tenant_spawn(coop)
    last_tenant_active = tenant_active

    if not tenant_active:
        peer_flashlight_hold.clear()
        return

    var target_peer: int = int(coop.get("tenant_target_peer"))
    if target_peer <= 0:
        target_peer = 1
    var target_panic: float = clampf(float(peer_panic.get(target_peer, 0.0)), 0.0, 100.0)
    coop.set("tenant_panic", target_panic)

    var tenant: Node3D = _tenant_node()
    if tenant != null:
        tenant.set("panic", target_panic)

    var panic_ratio: float = target_panic / 100.0
    var desired_cooldown: float = lerpf(tenant_base_attack_cooldown, tenant_min_attack_cooldown, panic_ratio)
    var current_timer: float = float(coop.get("tenant_attack_timer"))
    if current_timer > desired_cooldown:
        coop.set("tenant_attack_timer", desired_cooldown)

    if _update_flashlight_holds(delta):
        if coop.has_method("_server_stop_tenant"):
            coop.call("_server_stop_tenant")
        elif coop.has_method("request_tenant_stop"):
            coop.call("request_tenant_stop")
        peer_flashlight_hold.clear()
        last_tenant_active = false

func _update_flashlight_holds(delta: float) -> bool:
    var active_ids: Array[int] = []
    for peer_variant: Variant in peer_panic.keys():
        var peer_id: int = int(peer_variant)
        active_ids.append(peer_id)
        var contact: bool = bool(peer_flashlight_contact.get(peer_id, false))
        var hold: float = float(peer_flashlight_hold.get(peer_id, 0.0))
        hold = minf(tenant_flashlight_dismiss_seconds, hold + delta) if contact else 0.0
        peer_flashlight_hold[peer_id] = hold
        if hold >= tenant_flashlight_dismiss_seconds:
            return true

    for stored_variant: Variant in peer_flashlight_hold.keys():
        var stored_id: int = int(stored_variant)
        if not active_ids.has(stored_id):
            peer_flashlight_hold.erase(stored_id)
    return false

func _repair_new_tenant_spawn(coop: Node) -> void:
    var tenant: Node3D = _tenant_node()
    if tenant == null:
        return
    var target_peer: int = int(coop.get("tenant_target_peer"))
    if target_peer <= 0:
        target_peer = 1
    if not coop.has_method("_get_survivor_state"):
        return
    var state_value: Variant = coop.call("_get_survivor_state", target_peer)
    if not (state_value is Dictionary):
        return
    var state: Dictionary = Dictionary(state_value)
    var transform_value: Variant = state.get("transform", null)
    if not (transform_value is Transform3D):
        return
    var survivor_transform: Transform3D = transform_value

    var backward: Vector3 = survivor_transform.basis.z
    backward.y = 0.0
    if backward.length() <= 0.01:
        backward = Vector3(0.0, 0.0, 1.0)
    else:
        backward = backward.normalized()

    var spawn: Vector3 = survivor_transform.origin + backward * 4.2
    spawn.y = survivor_transform.origin.y - 0.92
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation != null and navigation.has_method("_clamp_monster_position"):
        var clamped_value: Variant = navigation.call("_clamp_monster_position", spawn)
        if clamped_value is Vector3:
            spawn = clamped_value
    tenant.global_position = spawn

func get_tenant_move_speed_for_panic(panic: float) -> float:
    return lerpf(tenant_base_move_speed, tenant_max_move_speed, clampf(panic / 100.0, 0.0, 1.0))

func get_tenant_attack_cooldown_for_panic(panic: float) -> float:
    return lerpf(tenant_base_attack_cooldown, tenant_min_attack_cooldown, clampf(panic / 100.0, 0.0, 1.0))

func _tenant_node() -> Node3D:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("Monster") as Node3D

func _on_peer_disconnected(peer_id: int) -> void:
    peer_panic.erase(peer_id)
    peer_flashlight_contact.erase(peer_id)
    peer_flashlight_hold.erase(peer_id)

func _reset_runtime_state() -> void:
    send_timer = 0.0
    peer_panic.clear()
    peer_flashlight_contact.clear()
    peer_flashlight_hold.clear()
    last_tenant_active = false

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
