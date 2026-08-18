extends Node

const FLASHLIGHT_RANGE: float = 65.0
const FLASHLIGHT_ENERGY: float = 9.50
const FLASHLIGHT_DIM_START_BATTERY: float = 75.0
const LOW_BATTERY_FLICKER_THRESHOLD: float = 22.0
const FULL_DARKNESS_AMBIENT: float = 0.05

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const MINE_SCENE_PATH: String = "res://scenes/mine.tscn"
const FACILITY_SCENE_PATH: String = "res://scenes/research_facility.tscn"

var last_scene_id: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    # Apply after Player.gd so the 75% battery curve becomes the final visual
    # output while retaining the existing panic and low-battery behavior.
    process_priority = 90

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != last_scene_id:
        last_scene_id = scene_id

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

        flashlight.spot_range = FLASHLIGHT_RANGE
        player.set("flashlight_base_energy", FLASHLIGHT_ENERGY)

        var battery: float = clampf(float(player.get("flashlight_battery")), 0.0, 100.0)
        if battery <= 0.0:
            flashlight.light_energy = 0.0
            continue

        # 100% through 75% stays at full 9.5 energy. Below 75%, brightness
        # drops proportionally with battery: 50%=6.33, 25%=3.17, 10%=1.27.
        var battery_factor: float = 1.0
        if battery < FLASHLIGHT_DIM_START_BATTERY:
            battery_factor = clampf(battery / FLASHLIGHT_DIM_START_BATTERY, 0.0, 1.0)

        # Preserve the existing low-battery instability, but only after the
        # smooth 75% brightness degradation has already taken effect.
        if battery <= LOW_BATTERY_FLICKER_THRESHOLD:
            var low_ratio: float = clampf(battery / LOW_BATTERY_FLICKER_THRESHOLD, 0.0, 1.0)
            var flicker: float = 0.62 + 0.38 * absf(sin(float(Time.get_ticks_msec()) / 72.0))
            battery_factor *= lerpf(0.48, 0.88, low_ratio) * flicker

        var panic_factor: float = 1.0
        var panic: float = clampf(float(player.get("flashlight_panic")), 0.0, 100.0)
        if panic >= 72.0:
            var panic_ratio: float = clampf((panic - 72.0) / 28.0, 0.0, 1.0)
            var panic_pulse: float = 0.72 + 0.28 * absf(sin(float(Time.get_ticks_msec()) / 85.0))
            panic_factor = lerpf(1.0, 0.58, panic_ratio) * panic_pulse

        flashlight.light_energy = FLASHLIGHT_ENERGY * battery_factor * panic_factor

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
