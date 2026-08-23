extends Node

# Contextual read-only intelligence for high-tier information talents. The HUD
# stays hidden unless a currently relevant talent has something actionable to
# say, so it does not become a permanent arcade overlay.

var layer: CanvasLayer
var panel: PanelContainer
var label: Label
var refresh_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 525
    _build_ui_v70()

func _process(delta: float) -> void:
    refresh_timer -= delta
    if refresh_timer > 0.0:
        return
    refresh_timer = 0.20
    _refresh_v70()

func _build_ui_v70() -> void:
    layer = CanvasLayer.new()
    layer.name = "ProgressionIntelHUDV70"
    layer.layer = 67
    add_child(layer)

    panel = PanelContainer.new()
    panel.name = "ContextualIntel"
    panel.visible = false
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel", _panel_style_v70())
    layer.add_child(panel)

    var margin: MarginContainer = MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_top", 7)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_bottom", 7)
    panel.add_child(margin)

    label = Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size", 12)
    margin.add_child(label)

func _refresh_v70() -> void:
    if panel == null or label == null:
        return
    var player: CharacterBody3D = _local_player_v70()
    if player == null or not _gameplay_active_v70() or _ui_blocked_v70():
        panel.visible = false
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("get_contextual_intel_v70"):
        panel.visible = false
        return
    var intel_value: Variant = progression.call("get_contextual_intel_v70", player)
    if not (intel_value is Dictionary):
        panel.visible = false
        return
    var intel: Dictionary = Dictionary(intel_value)
    var text: String = str(intel.get("text", "")).strip_edges()
    if text.is_empty():
        panel.visible = false
        return
    label.text = "%s\n%s" % [str(intel.get("title", "FIELD INTEL")), text]
    panel.visible = true
    _layout_v70()

func _layout_v70() -> void:
    if panel == null or label == null:
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _mobile_active_v70() or viewport.x < 800.0
    var width: float = minf(310.0 if compact else 430.0, maxf(220.0, viewport.x - 24.0))
    panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
    if compact:
        panel.position = Vector2((viewport.x - width) * 0.5, 98.0)
        label.add_theme_font_size_override("font_size", 11)
    else:
        panel.position = Vector2(maxf(12.0, viewport.x - width - 24.0), 92.0)
        label.add_theme_font_size_override("font_size", 12)
    panel.size = Vector2(width, 0.0)

func _panel_style_v70() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.012, 0.016, 0.022, 0.90)
    style.border_color = Color(0.40, 0.52, 0.58, 0.52)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 7
    style.corner_radius_top_right = 7
    style.corner_radius_bottom_left = 7
    style.corner_radius_bottom_right = 7
    return style

func _ui_blocked_v70() -> bool:
    var lock: Node = get_node_or_null("/root/GameplayInputLock")
    if lock != null and lock.has_method("is_locked"):
        return bool(lock.call("is_locked"))
    return false

func _gameplay_active_v70() -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return false
    return scene.scene_file_path not in ["res://scenes/main_menu.tscn", "res://scenes/main_menu_ranger.tscn"]

func _mobile_active_v70() -> bool:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    return mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))

func _local_player_v70() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func get_intel_hud_contract_v70() -> Dictionary:
    return {
        "contextual_only": true,
        "threat_escape_guidance": true,
        "mine_circuit_guidance": true,
        "generator_warning_guidance": true,
        "desktop_responsive": true,
        "mobile_responsive": true,
        "new_art_required": false,
        "changes_world_authority": false
    }
