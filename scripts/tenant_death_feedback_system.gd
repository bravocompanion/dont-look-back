extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@export var kill_arm_seconds: float = 2.82

var last_scene_id: int = 0
var last_tenant_active: bool = false
var kill_armed: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 15

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _reset_state()
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != last_scene_id:
        last_scene_id = scene_id
        last_tenant_active = _tenant_active()
        kill_armed = false
        return

    var tenant_active: bool = _tenant_active()
    if tenant_active:
        kill_armed = _flashlight_kill_near_complete()

    if last_tenant_active and not tenant_active and kill_armed:
        _play_death_feedback()
        kill_armed = false

    if not tenant_active and not last_tenant_active:
        kill_armed = false

    last_tenant_active = tenant_active

func _flashlight_kill_near_complete() -> bool:
    var panic_system: Node = get_node_or_null("/root/PanicTenantSystem")
    if panic_system != null and panic_system.has_method("get_tenant_flashlight_hold"):
        if float(panic_system.call("get_tenant_flashlight_hold")) >= kill_arm_seconds:
            return true

    if not _network_online() or not _is_host():
        return false

    var bridge: Node = get_node_or_null("/root/TenantPanicNetworkBridge")
    if bridge == null:
        return false
    var holds_value: Variant = bridge.get("peer_flashlight_hold")
    if not (holds_value is Dictionary):
        return false
    var holds: Dictionary = Dictionary(holds_value)
    for hold_variant: Variant in holds.values():
        if float(hold_variant) >= kill_arm_seconds:
            return true
    return false

func _tenant_active() -> bool:
    if _network_online():
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null:
            return bool(coop.get("tenant_active"))

    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D
    return tenant != null and is_instance_valid(tenant) and tenant.visible and bool(tenant.get("active"))

func _play_death_feedback() -> void:
    if _network_online():
        if not _is_host():
            return
        _play_tenant_death_local()
        _receive_tenant_death_feedback.rpc()
        return
    _play_tenant_death_local()

@rpc("authority", "call_remote", "reliable", 18)
func _receive_tenant_death_feedback() -> void:
    _play_tenant_death_local()

func _play_tenant_death_local() -> void:
    var audio: Node = get_node_or_null("/root/DynamicAudioSystem")
    if audio != null and audio.has_method("play_tenant_death"):
        audio.call("play_tenant_death")

func _reset_state() -> void:
    last_scene_id = 0
    last_tenant_active = false
    kill_armed = false

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))
