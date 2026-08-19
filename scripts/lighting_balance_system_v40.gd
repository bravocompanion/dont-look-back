extends "res://scripts/lighting_balance_system.gd"

# v0.31 cone was 36.4 degrees. v0.40 makes the illuminated area 20% smaller.
const FLASHLIGHT_SPOT_ANGLE_V40: float = 29.12

func _configure_player_flashlights() -> void:
    super._configure_player_flashlights()
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
        if flashlight != null:
            flashlight.spot_angle = FLASHLIGHT_SPOT_ANGLE_V40
