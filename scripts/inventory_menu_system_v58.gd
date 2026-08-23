extends "res://scripts/inventory_menu_system_v57.gd"

const INVENTORY_LOCK_REASON_V71: String = "INVENTORY_MENU_V71"

func _set_inventory_open(value: bool) -> void:
    if value and not _can_open_inventory():
        return
    if inventory_open == value:
        return

    inventory_open = value
    if overlay != null:
        overlay.visible = value
    if panel != null:
        panel.visible = value
    if bag_button != null:
        bag_button.visible = not value and _can_open_inventory()

    if value:
        if active_player != null:
            active_player.velocity = Vector3.ZERO
        _set_central_lock_v71(true)
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        last_signature = ""
        _refresh_inventory(true)
    else:
        _set_central_lock_v71(false)
        if not _mobile_active() and not _central_ui_locked_v71() and not _blocked_elsewhere():
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _apply_responsive_layout() -> void:
    super._apply_responsive_layout()
    if bag_button == null:
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport_size))
    var rect_value: Variant = layout.get("bag_button", null)
    if rect_value is Rect2:
        var rect: Rect2 = rect_value
        bag_button.position = rect.position
        bag_button.size = rect.size

func _set_central_lock_v71(locked: bool) -> void:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock == null:
        return
    if locked and input_lock.has_method("acquire"):
        input_lock.call("acquire", INVENTORY_LOCK_REASON_V71)
    elif not locked and input_lock.has_method("release"):
        input_lock.call("release", INVENTORY_LOCK_REASON_V71)

func _central_ui_locked_v71() -> bool:
    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    return input_lock != null and input_lock.has_method("is_locked") and bool(input_lock.call("is_locked"))

func get_inventory_collision_contract_v71() -> Dictionary:
    return {
        "movement_authority": "GameplayInputLock",
        "direct_player_physics_ownership": false,
        "direct_player_process_ownership": false,
        "direct_mobile_external_block_ownership": false,
        "manual_same_frame_lock": true,
        "progression_menu_exclusive": true,
        "coordinated_bag_button_layout": true,
        "weight_ui_retained": true
    }
