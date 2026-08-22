extends Node

# v0.63 centralizes the meaning of protective light. Darkness may be repelled by
# the survivor flashlight OR authored/world protection. Tenant protection uses
# world protection only, preserving the rule that a flashlight is not a safe zone.

const WORLD_LIGHT_RADIUS_FACTOR: float = 0.82
const WORLD_LIGHT_MIN_ENERGY: float = 0.10
const REFRESH_INTERVAL_SECONDS: float = 0.75

var cached_scene_id: int = 0
var cached_world_lights: Array[OmniLight3D] = []
var refresh_remaining: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    refresh_remaining = maxf(0.0, refresh_remaining - delta)
    var scene: Node = get_tree().current_scene
    var scene_id: int = int(scene.get_instance_id()) if scene != null else 0
    if scene_id != cached_scene_id:
        cached_scene_id = scene_id
        cached_world_lights.clear()
        refresh_remaining = 0.0

func is_player_protected_from_darkness_v63(player: CharacterBody3D) -> bool:
    if player == null:
        return false
    if _player_flashlight_active_v63(player):
        return true
    return is_position_world_protected_v63(player.global_position)

func is_player_world_protected_v63(player: CharacterBody3D) -> bool:
    return player != null and is_position_world_protected_v63(player.global_position)

func is_position_world_protected_v63(world_position: Vector3) -> bool:
    var ranger_safe_zone: Node = get_node_or_null("/root/RangerSafeZone")
    if ranger_safe_zone != null and ranger_safe_zone.has_method("is_threat_protected_position_v56"):
        if bool(ranger_safe_zone.call("is_threat_protected_position_v56", world_position)):
            return true

    _refresh_world_lights_v63()
    for light: OmniLight3D in cached_world_lights:
        if light == null or not is_instance_valid(light):
            continue
        if not light.visible or light.light_energy <= WORLD_LIGHT_MIN_ENERGY:
            continue
        if light.is_in_group("non_protective_light") or bool(light.get_meta("non_protective_light_v63", false)):
            continue
        var protection_radius: float = maxf(0.0, light.omni_range * WORLD_LIGHT_RADIUS_FACTOR)
        if world_position.distance_to(light.global_position) <= protection_radius:
            return true
    return false

func get_light_contract_v63() -> Dictionary:
    return {
        "darkness_accepts_flashlight": true,
        "tenant_accepts_flashlight": false,
        "world_light_min_energy": WORLD_LIGHT_MIN_ENERGY,
        "world_light_radius_factor": WORLD_LIGHT_RADIUS_FACTOR
    }

func invalidate_cache_v63() -> void:
    refresh_remaining = 0.0

func _player_flashlight_active_v63(player: CharacterBody3D) -> bool:
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight == null:
        return false
    var battery: float = float(player.get("flashlight_battery"))
    return flashlight.visible and battery > 0.0 and flashlight.light_energy > 0.35

func _refresh_world_lights_v63() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        cached_world_lights.clear()
        refresh_remaining = REFRESH_INTERVAL_SECONDS
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != cached_scene_id:
        cached_scene_id = scene_id
        cached_world_lights.clear()
        refresh_remaining = 0.0

    if refresh_remaining > 0.0 and not cached_world_lights.is_empty():
        return

    cached_world_lights.clear()
    _collect_world_lights_v63(scene)
    refresh_remaining = REFRESH_INTERVAL_SECONDS

func _collect_world_lights_v63(node: Node) -> void:
    for child: Node in node.get_children():
        if child is OmniLight3D:
            cached_world_lights.append(child as OmniLight3D)
        _collect_world_lights_v63(child)
