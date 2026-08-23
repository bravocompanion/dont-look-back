extends "res://scripts/lighting_balance_system_v40.gd"

func _configure_player_flashlights() -> void:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("get_panic_multiplier_v68"):
        super._configure_player_flashlights()
        return

    var panic_multiplier: float = clampf(float(progression.call("get_panic_multiplier_v68")), 0.5, 1.0)
    var original_panic: Dictionary = {}
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        var player_id: int = int(player.get_instance_id())
        original_panic[player_id] = float(player.get("flashlight_panic"))
        player.set("flashlight_panic", float(player.get("flashlight_panic")) * panic_multiplier)

    super._configure_player_flashlights()

    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        var player_id: int = int(player.get_instance_id())
        if original_panic.has(player_id):
            player.set("flashlight_panic", float(original_panic[player_id]))

func get_focus_lighting_contract_v68() -> Dictionary:
    return {
        "focus_panic_reduction_per_point": 0.01,
        "steady_hands_reduction_per_rank": 0.05,
        "minimum_effective_panic_multiplier": 0.65,
        "flashlight_range_bonus": 0.0,
        "darkness_immunity": false
    }
