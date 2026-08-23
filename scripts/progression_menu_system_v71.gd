extends "res://scripts/progression_menu_system_v70.gd"

func _set_open_v68(value: bool) -> void:
    if value and _blocked_elsewhere_v68():
        return
    if menu_open == value:
        return
    menu_open = value
    if overlay != null:
        overlay.visible = value
    if panel != null:
        panel.visible = value
    if open_button != null:
        open_button.visible = not value

    if value:
        active_tab = TAB_OVERVIEW
        last_signature = ""
        _acquire_lock_v68()
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        _refresh_v68()
    else:
        _release_lock_v68()
        if not _mobile_v68() and not _central_ui_locked_v71() and not _blocked_elsewhere_v68():
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _layout_v68() -> void:
    super._layout_v68()
    if open_button == null:
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport))
    var rect_value: Variant = layout.get("prog_button", null)
    if rect_value is Rect2:
        var rect: Rect2 = rect_value
        open_button.position = rect.position
        open_button.size = rect.size

func _central_ui_locked_v71() -> bool:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    return input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked"))

func get_progression_menu_collision_contract_v71() -> Dictionary:
    return {
        "movement_authority": "GameplayInputLock",
        "direct_mobile_external_block_ownership": false,
        "manual_same_frame_lock": true,
        "coordinated_prog_button_layout": true,
        "inventory_exclusive": true,
        "desktop_responsive": true,
        "mobile_responsive": true
    }
