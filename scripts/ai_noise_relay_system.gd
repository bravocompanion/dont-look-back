extends Node

func report_noise(position: Vector3, strength: float = 0.65, label: String = "noise") -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if not online:
        _deliver_noise(position, strength, label, 1)
        return

    var hosting: bool = network.has_method("is_server") and bool(network.call("is_server"))
    if hosting:
        _deliver_noise(position, strength, label, 1)
    else:
        _submit_noise.rpc_id(1, position, strength, label)

@rpc("any_peer", "call_remote", "reliable", 6)
func _submit_noise(position: Vector3, strength: float, label: String) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _deliver_noise(position, strength, label, sender_id)

func _deliver_noise(position: Vector3, strength: float, label: String, peer_id: int) -> void:
    var navigation: Node = get_node_or_null("/root/AINavigationSystem")
    if navigation == null or not navigation.has_method("report_noise"):
        return
    navigation.call("report_noise", position, strength, label, peer_id)
