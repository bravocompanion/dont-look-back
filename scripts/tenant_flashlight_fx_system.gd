extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@export var minimum_flicker_hz: float = 8.0
@export var maximum_flicker_hz: float = 12.0
@export var minimum_energy_factor: float = 0.22
@export var maximum_energy_factor: float = 0.96

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 80

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        return

    var panic_system: Node = get_node_or_null("/root/PanicTenantSystem")
    if panic_system == null or not panic_system.has_method("is_tenant_in_flashlight"):
        return
    if not bool(panic_system.call("is_tenant_in_flashlight")):
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not player.can_process() or bool(player.get("is_dead")):
        return
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    if flashlight == null or not flashlight.visible or float(player.get("flashlight_battery")) <= 0.0:
        return

    var hold: float = 0.0
    if panic_system.has_method("get_tenant_flashlight_hold"):
        hold = clampf(float(panic_system.call("get_tenant_flashlight_hold")), 0.0, 3.0)
    var strength: float = clampf(hold / 3.0, 0.0, 1.0)

    var frequency: float = lerpf(minimum_flicker_hz, maximum_flicker_hz, strength)
    var seconds: float = float(Time.get_ticks_msec()) / 1000.0
    var primary_wave: float = 0.5 + 0.5 * sin(seconds * frequency * TAU)
    var secondary_wave: float = 0.5 + 0.5 * sin(seconds * (frequency * 0.47) * TAU + 1.7)
    var irregular_wave: float = clampf(primary_wave * 0.82 + secondary_wave * 0.18, 0.0, 1.0)

    var low_factor: float = lerpf(0.38, minimum_energy_factor, strength)
    var high_factor: float = lerpf(0.88, maximum_energy_factor, strength)
    var rapid_factor: float = lerpf(low_factor, high_factor, irregular_wave)
    flashlight.light_energy *= rapid_factor
