extends "res://scripts/front_end_system_v182.gd"

const VERSION_BADGE_TEXT_V52: String = "v0.52  •  HARVESTABLE CORPSES  •  STRONGER BOW SWAY"

func _ensure_runtime_support_systems() -> void:
    _ensure_root_system("PanicTenantSystem", "res://scripts/panic_tenant_system_v51.gd")
    _ensure_root_system("PanicInputSystem", "res://scripts/panic_input_system.gd")
    _ensure_root_system("FlashlightMotionSystem", "res://scripts/flashlight_motion_system_v40.gd")
    _ensure_root_system("TenantFlashlightFXSystem", "res://scripts/tenant_flashlight_fx_system.gd")
    _ensure_root_system("DynamicAudioSystem", "res://scripts/dynamic_audio_system.gd")
    _ensure_root_system("TenantPanicNetworkBridge", "res://scripts/tenant_panic_network_bridge.gd")
    _ensure_root_system("TenantDeathFeedbackSystem", "res://scripts/tenant_death_feedback_system.gd")

func _process(delta: float) -> void:
    super._process(delta)
    var scene: Node = get_tree().current_scene
    if scene == null or not _is_main_menu_scene(scene):
        return
    var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null and version_label.text != VERSION_BADGE_TEXT_V52:
        version_label.text = VERSION_BADGE_TEXT_V52
