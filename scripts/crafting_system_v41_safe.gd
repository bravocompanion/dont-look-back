extends "res://scripts/crafting_system_v41.gd"

func open_workbench(workbench: Node3D = null) -> void:
    super.open_workbench(workbench)
    if menu_open and active_player != null:
        active_player.velocity = Vector3.ZERO
        active_player.set_process_unhandled_input(false)

func close_workbench() -> void:
    var player: CharacterBody3D = active_player
    super.close_workbench()
    if player != null and is_instance_valid(player) and not _other_menu_open():
        player.set_process_unhandled_input(true)

func _unhandled_key_input(event: InputEvent) -> void:
    if not menu_open or not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    if key_event.physical_keycode == KEY_ESCAPE:
        close_workbench()
    # While crafting owns the screen, suppress Journal/Inventory/Co-op/Status
    # shortcuts so another overlay cannot be opened underneath it.
    get_viewport().set_input_as_handled()
