extends "res://scripts/forest_survival_system_v27.gd"

# v0.38 English-only forest survival text.

func on_animal_killed(animal_id: String, animal_kind: String, hunter_peer_id: int, death_position: Vector3) -> void:
    if not _is_authoritative():
        return
    respawn_timers[animal_id] = animal_respawn_seconds
    _emit_blood_mark(death_position, animal_kind)
    _spawn_or_replace_carcass(animal_id, animal_kind, death_position)
    _message_peer(
        hunter_peer_id,
        "HUNT: %s is down. Follow the blood trail and harvest the carcass with the Hunting Knife before leaving it." % animal_kind.capitalize()
    )
    _broadcast_wildlife_state()

func request_harvest(carcass_id: String) -> void:
    if not forest_active or _ui_blocked():
        return
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "hunting_knife")):
        _objective(player, "You need the Hunting Knife to harvest the carcass without damaging the meat and hide.")
        return

    var peer_id: int = _local_peer_id()
    if _network_online() and not _is_authoritative():
        _request_harvest_remote.rpc_id(1, carcass_id)
    else:
        _resolve_harvest(peer_id, carcass_id)

func _resolve_harvest(peer_id: int, carcass_id: String) -> void:
    if not carcass_records.has(carcass_id):
        _message_peer(peer_id, "That carcass can no longer be harvested.")
        return
    var record: Dictionary = Dictionary(carcass_records.get(carcass_id, {}))
    if bool(record.get("harvested", false)):
        _message_peer(peer_id, "That carcass was already harvested by another teammate.")
        return

    record["harvested"] = true
    carcass_records[carcass_id] = record
    carcass_decay[carcass_id] = 4.0
    _set_carcass_harvested_local(carcass_id, true)
    if _network_online():
        _receive_carcass_harvested.rpc(carcass_id)

    var animal_kind: String = str(record.get("kind", "deer"))
    var loot: Dictionary = _loot_for_kind(animal_kind)
    _grant_loot_to_peer(
        peer_id,
        loot,
        "HARVEST: %s harvested — %s. Raw food must be cooked at the campfire." % [animal_kind.capitalize(), _loot_summary(loot)]
    )

func _update_ui(player: CharacterBody3D) -> void:
    if not forest_active:
        _set_ui_visible(false)
        return
    _set_ui_visible(true)

    var weather_name: String = "CLEAR"
    match current_weather:
        "cloudy": weather_name = "CLOUDY"
        "rain": weather_name = "RAIN"
        "storm": weather_name = "STORM"
    if weather_label != null:
        weather_label.text = "WEATHER %s  •  WET %d%%" % [weather_name, int(round(wetness))]

    if weather_tint != null:
        match current_weather:
            "storm": weather_tint.color = Color(0.06, 0.08, 0.12, 0.14)
            "rain": weather_tint.color = Color(0.08, 0.10, 0.13, 0.08)
            "cloudy": weather_tint.color = Color(0.08, 0.08, 0.09, 0.035)
            _: weather_tint.color = Color(0.0, 0.0, 0.0, 0.0)

    if hunt_button != null:
        var has_bow: bool = player != null and player.has_method("has_item") and bool(player.call("has_item", "hunting_bow"))
        hunt_button.visible = _mobile_active() and has_bow and not _ui_blocked()
        var size: Vector2 = get_viewport().get_visible_rect().size
        hunt_button.position = Vector2(size.x - 116.0, maxf(120.0, size.y * 0.30))
