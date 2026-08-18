extends Node

const FLASHLIGHT_RANGE: float = 65.0
const FLASHLIGHT_ENERGY: float = 4.20
const FULL_DARKNESS_AMBIENT: float = 0.05

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const MINE_SCENE_PATH: String = "res://scenes/mine.tscn"
const FACILITY_SCENE_PATH: String = "res://scenes/research_facility.tscn"

var configured_players: Dictionary = {}
var last_scene_id: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Run after the regular gameplay/director passes so the final visual floor
    # is deterministic without fighting the player's low-battery flicker.
    process_priority = 90

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != last_scene_id:
        last_scene_id = scene_id
        configured_players.clear()

    _configure_player_flashlights()
    _apply_full_darkness_floor(scene)

func _configure_player_flashlights() -> void:
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue

        var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
        if flashlight == null:
            continue

        # Range is always enforced because scene transitions instantiate a new
        # player and every gameplay map should use the same flashlight reach.
        flashlight.spot_range = FLASHLIGHT_RANGE

        # Player.gd calculates flicker from flashlight_base_energy. Configure
        # that base once, then leave light_energy alone on later frames so low
        # battery and panic flicker continue to work normally.
        player.set("flashlight_base_energy", FLASHLIGHT_ENERGY)

        var player_id: int = int(player.get_instance_id())
        if not configured_players.has(player_id):
            configured_players[player_id] = true
            if float(player.get("flashlight_battery")) > 0.0 and flashlight.visible:
                flashlight.light_energy = FLASHLIGHT_ENERGY

func _apply_full_darkness_floor(scene: Node) -> void:
    var scene_path: String = scene.scene_file_path
    if scene_path != LABYRINTH_SCENE_PATH and scene_path != MINE_SCENE_PATH and scene_path != FACILITY_SCENE_PATH:
        return

    var world_environment: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        return

    # Underground maps use local lamps/flashlight for readable areas. The
    # unlit baseline stays at 5% instead of becoming absolute black.
    world_environment.environment.ambient_light_energy = FULL_DARKNESS_AMBIENT
