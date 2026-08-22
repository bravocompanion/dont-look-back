extends "res://scripts/coop_horror_system_v59.gd"

# v0.63 keeps host authority from v0.59 but removes duplicated light meaning.
# Tenant reads WORLD protection only. Darkness reads flashlight OR world protection.

func _collect_local_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_local_state(player)
    var registry: Node = get_node_or_null("/root/LightRegistry")
    if registry != null:
        if registry.has_method("is_player_world_protected_v63"):
            state["world_light"] = bool(registry.call("is_player_world_protected_v63", player))
        if registry.has_method("is_player_protected_from_darkness_v63"):
            state["in_light"] = bool(registry.call("is_player_protected_from_darkness_v63", player))
    return state

func _player_near_world_light_v51(target_player: CharacterBody3D) -> bool:
    if target_player == null:
        return false
    var registry: Node = get_node_or_null("/root/LightRegistry")
    if registry != null and registry.has_method("is_player_world_protected_v63"):
        return bool(registry.call("is_player_world_protected_v63", target_player))
    return super._player_near_world_light_v51(target_player)

func get_light_authority_contract_v63() -> Dictionary:
    return {
        "tenant_uses_world_light": true,
        "tenant_uses_flashlight": false,
        "darkness_uses_flashlight_or_world": true,
        "online_darkness_owner": "coop_host"
    }
