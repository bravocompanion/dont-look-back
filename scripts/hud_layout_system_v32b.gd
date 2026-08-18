extends "res://scripts/hud_layout_system_v32.gd"

func _apply_gameplay_layout() -> void:
    super._apply_gameplay_layout()
    if tracked_player == null or tracked_hud == null:
        return

    var size: Vector2 = tracked_player.get_viewport().get_visible_rect().size
    var compact: bool = _is_mobile_layout() or size.x < 800.0
    var margin: float = 10.0 if compact else 24.0
    var bar_height: float = 46.0 if compact else 52.0
    var top_margin: float = 5.0 if compact else 16.0
    var secondary_y: float = bar_height + top_margin + 76.0

    # Use absolute top-left coordinates for edge-aligned labels so their final
    # rect is independent of whatever anchor preset the original scene used.
    var panic: Label = tracked_player.get_node_or_null("HUD/PanicLabel") as Label
    if panic != null:
        var panic_width: float = 102.0 if compact else 166.0
        panic.set_anchors_preset(Control.PRESET_TOP_LEFT)
        panic.position = Vector2(size.x - margin - panic_width, secondary_y)
        panic.size = Vector2(panic_width, 24.0)
        panic.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

    var controls: Label = tracked_player.get_node_or_null("HUD/Controls") as Label
    if controls != null and controls.visible:
        controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
        controls.position = Vector2(24.0, maxf(0.0, size.y - 34.0))
        controls.size = Vector2(minf(900.0, size.x - 48.0), 26.0)

func _layout_journal() -> void:
    super._layout_journal()
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var panel: PanelContainer = journal.get("journal_panel") as PanelContainer
    if panel == null:
        return

    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = _is_mobile_layout() or size.x < 800.0
    panel.anchor_left = 0.5
    panel.anchor_top = 0.5
    panel.anchor_right = 0.5
    panel.anchor_bottom = 0.5

    if compact:
        var width: float = clampf(size.x - 20.0, 260.0, 520.0)
        var height: float = clampf(size.y - 52.0, 360.0, 650.0)
        panel.offset_left = -width * 0.5
        panel.offset_top = -height * 0.5
        panel.offset_right = width * 0.5
        panel.offset_bottom = height * 0.5
    else:
        var width_desktop: float = minf(760.0, size.x - 80.0)
        var height_desktop: float = minf(600.0, size.y - 80.0)
        panel.offset_left = -width_desktop * 0.5
        panel.offset_top = -height_desktop * 0.5
        panel.offset_right = width_desktop * 0.5
        panel.offset_bottom = height_desktop * 0.5
