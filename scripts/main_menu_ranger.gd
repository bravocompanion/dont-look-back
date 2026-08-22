extends "res://scripts/main_menu.gd"

const RANGER_START_SCENE_PATH: String = "res://scenes/forest.tscn"

func _ready() -> void:
    super._ready()
    version_label.text = "v0.56  •  CO-OP SUPPLY SCALING  •  POWERED SAFE ZONE"
    save_summary.tooltip_text = "Ranger Forest starts at 12:00. Larger co-op parties gain extra shared POI supplies, while the ranger yard is only threat-safe when the generator or campfire is active."
    new_game_button.tooltip_text = "Solo and duo keep the tighter base economy. Scavenge, craft, gather renewable Wood, maintain generator condition, and keep real shelter light available before relying on the yard at night."
    host_button.tooltip_text = "HOST keeps shared pickups authoritative. Parties of 3 and 4 dynamically receive extra deterministic materials at House, Gas Station, Warehouse and Mine; unclaimed bonus supplies disappear if party size drops."
    join_button.tooltip_text = "The yard fence alone no longer stops threats. Generator power or an active campfire enables full Ranger Yard protection; player flashlights do not count as shelter protection."
    _set_status("RANGER CASE 07 — Survive, share supplies, maintain shelter power, and follow the evidence underground.")

func _start_new_game() -> void:
    if scene_booting:
        return
    _set_menu_buttons_enabled(false)
    _set_status("Preparing the ranger station at 12:00...")
    _disconnect_network()

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null:
        if save_system.has_method("delete_save") and not bool(save_system.call("delete_save")):
            _set_menu_buttons_enabled(true)
            _show_main()
            _set_status("Failed to delete the previous save.")
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
        _set_status("NetworkManager is not available.")
        return
    network.call("host_game")
    if not (network.has_method("is_online") and bool(network.call("is_online"))):
        _set_status("Failed to create the HOST session.")
        return
    _set_menu_buttons_enabled(false)
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("_prepare_clean_reload"):
        save_system.call("_prepare_clean_reload")
    _enter_scene_safely(RANGER_START_SCENE_PATH, "HOST CO-OP — RANGER STATION")

func _process_join(delta: float) -> void:
    join_elapsed += delta
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("NetworkManager is not available.")
        return

    var online: bool = network.has_method("is_online") and bool(network.call("is_online"))
    var connecting: bool = bool(network.get("connecting"))
    if online:
        _set_status("Connected. Preparing the ranger investigation...")
        if join_elapsed >= 1.0:
            join_waiting = false
            _enter_scene_safely(RANGER_START_SCENE_PATH, "JOIN CO-OP — RANGER STATION")
        return

    if not connecting and join_elapsed > 0.35:
        join_waiting = false
        join_connect_button.disabled = false
        _set_status("Connection failed. Check the HOST IP address.")

func _show_main() -> void:
    super._show_main()
    if not scene_booting:
        _set_status("NEW GAME: 12:00 Ranger Forest → powered shelter nights → Day 3 radiation → Old Mine → Labyrinth → Research Facility.")
