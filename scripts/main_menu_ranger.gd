extends "res://scripts/main_menu.gd"

const RANGER_START_SCENE_PATH: String = "res://scenes/forest.tscn"

func _ready() -> void:
    super._ready()
    version_label.text = "v0.36  •  RANGER INVESTIGATION  •  ID / EN  •  STABLE UI"
    save_summary.tooltip_text = "Game dimulai di Ranger Forest. Progress mengikuti Forest → Mine → Labyrinth → Research Facility."
    new_game_button.tooltip_text = "Mulai sebagai ranger di cabin forest. Survival dulu, lalu ikuti evidence."
    host_button.tooltip_text = "Host co-op dimulai di Ranger Forest yang sama."
    join_button.tooltip_text = "Join host dan sinkron ke scene investigasi host."
    _set_status("RANGER CASE 07 — Survive the forest, investigate the missing survey team, then follow the evidence underground.")

func _start_new_game() -> void:
    if scene_booting:
        return
    _set_menu_buttons_enabled(false)
    _set_status("Menyiapkan ranger station di forest...")
    _disconnect_network()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save") and not bool(save_system.call("delete_save")):
            _set_menu_buttons_enabled(true)
            _show_main()
            _set_status("Save lama gagal dihapus.")
            return
        if save_system.has_method("_prepare_clean_reload"):
            save_system.call("_prepare_clean_reload")

    var movement: Node = get_node_or_null("/root/MovementSystem")
    if movement != null:
        movement.set("tracked_player_id", 0)
        movement.set("coyote_timer", 0.0)
        movement.set("jump_buffer_timer", 0.0)

    _enter_scene_safely(RANGER_START_SCENE_PATH, "NEW GAME — RANGER DEPLOYMENT")

func _host_game() -> void:
    if scene_booting:
        return
    _disconnect_network()
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("host_game"):
        _set_status("NetworkManager tidak tersedia.")
        return
    network.call("host_game")
    if not (network.has_method("is_online") and bool(network.call("is_online"))):
        _set_status("HOST gagal dibuat.")
        return
    _set_menu_buttons_enabled(false)
    _enter_scene_safely(RANGER_START_SCENE_PATH, "HOST CO-OP — RANGER STATION")

func _process_join(delta: float) -> void:
    join_elapsed += delta
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("NetworkManager tidak tersedia.")
        return

    var online: bool = network.has_method("is_online") and bool(network.call("is_online"))
    var connecting: bool = bool(network.get("connecting"))
    if online:
        _set_status("Terhubung. Menyiapkan ranger investigation...")
        if join_elapsed >= 1.0:
            join_waiting = false
            _enter_scene_safely(RANGER_START_SCENE_PATH, "JOIN CO-OP — RANGER STATION")
        return

    if not connecting and join_elapsed > 0.35:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("Gagal terhubung. Periksa IP HOST.")

func _show_main() -> void:
    super._show_main()
    if not scene_booting:
        _set_status("NEW GAME: Ranger Forest → evidence → Old Mine → Labyrinth → Research Facility.")
