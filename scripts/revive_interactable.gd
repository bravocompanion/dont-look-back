extends StaticBody3D

@export var peer_id: int = 0

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/CoopHorrorSystem")
    if system != null and system.has_method("is_survivor_downed"):
        if bool(system.call("is_survivor_downed", peer_id)):
            var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
            if polish != null and polish.has_method("get_player_name"):
                return "Revive %s" % str(polish.call("get_player_name", peer_id))
            return "Revive Survivor %d" % peer_id
    return "Survivor %d" % peer_id

func interact() -> void:
    var system: Node = get_node_or_null("/root/CoopHorrorSystem")
    if system == null or not system.has_method("request_revive"):
        return
    if not bool(system.call("is_survivor_downed", peer_id)):
        return

    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    if polish != null and polish.has_method("begin_local_revive"):
        polish.call("begin_local_revive", peer_id)

    system.call("request_revive", peer_id)
