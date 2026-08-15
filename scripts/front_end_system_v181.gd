extends "res://scripts/front_end_system.gd"

const LABYRINTH_SCENE_PATH_V181: String = "res://scenes/main.tscn"

func _ready() -> void:
    super._ready()
    if title_box != null and title_box.get_child_count() > 1:
        var subtitle: Label = title_box.get_child(1) as Label
        if subtitle != null:
            subtitle.text = "v0.18.1  •  SURVIVAL HORROR"

func _start_new_game_confirmed() -> void:
    get_tree().paused = false
    pending_join = false
    title_resume_available = false
    _disconnect_network_if_needed()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save"):
            save_system.call("delete_save")
        if save_system.has_method("_prepare_clean_reload"):
            save_system.call("_prepare_clean_reload")

    var change_error: Error = get_tree().change_scene_to_file(LABYRINTH_SCENE_PATH_V181)
    if change_error != OK:
        _set_status("New Game failed: labyrinth map could not load.")
        _show_title_menu()
        return

    current_mode = "boot_new"
    _set_all_panels_hidden()
    overlay.visible = true
    _set_status("Starting a new nightmare...")
    call_deferred("_finish_new_game_after_reload")
