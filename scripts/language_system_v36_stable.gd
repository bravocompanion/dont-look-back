extends "res://scripts/language_system_v35_hotfix.gd"

# v0.36 language stability pass.
# Prevents double-toggle clicks and removes visible EN/ID oscillation from
# dynamic HUD writers that refresh at different timers.

var full_refresh_timer_v36: float = 0.0
var tracked_scene_v36: int = 0

func _ready() -> void:
    super._ready()
    # Gameplay UI writers use the default priority. Run localization late in
    # the same frame so untranslated intermediate text is never rendered.
    process_priority = 1000
    full_refresh_timer_v36 = 0.0
    tracked_scene_v36 = 0

func _process(delta: float) -> void:
    # Do not call the parent _process(). The old 0.12 s localization timer was
    # the main source of visible EN/ID flicker on frequently refreshed labels.
    control_timer -= delta
    if control_timer <= 0.0:
        control_timer = 0.35
        _ensure_language_controls()

    var scene: Node = get_tree().current_scene
    var scene_id: int = 0
    if scene != null:
        scene_id = int(scene.get_instance_id())

    if scene_id != tracked_scene_v36:
        tracked_scene_v36 = scene_id
        full_refresh_timer_v36 = 0.0

    # Only volatile UI is corrected every frame. This is intentionally small
    # enough for mobile while running after the gameplay writers.
    _stabilize_live_text_v36(scene)

    # Static labels, world labels and journal source data do not need a full
    # tree pass every frame.
    full_refresh_timer_v36 -= delta
    if full_refresh_timer_v36 <= 0.0:
        full_refresh_timer_v36 = 0.75
        _apply_localization()

func _input(event: InputEvent) -> void:
    # Pointer/touch clicks are handled only by Button.pressed. The base script
    # also hit-tested LanguageToggle buttons globally, causing one click to
    # toggle twice. Keep keyboard L as the only global input path.
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.physical_keycode != KEY_L:
        return
    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus is LineEdit:
        return
    _toggle_language()
    get_viewport().set_input_as_handled()

func _ensure_language_controls() -> void:
    super._ensure_language_controls()
    _ensure_single_toggle_connection_v36(top_language_button)
    _ensure_single_toggle_connection_v36(journal_language_button)

func _ensure_single_toggle_connection_v36(button: Button) -> void:
    if button == null or not is_instance_valid(button):
        return
    var callback: Callable = Callable(self, "_toggle_language")
    if not button.pressed.is_connected(callback):
        button.pressed.connect(callback)

func _stabilize_live_text_v36(scene: Node) -> void:
    _stabilize_player_hud_v36()
    _stabilize_journal_v36()
    _stabilize_forest_runtime_v36()
    _stabilize_condition_runtime_v36()
    _stabilize_multiplayer_runtime_v36()
    _stabilize_frontend_status_v36()
    if scene != null and scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _stabilize_ranger_menu_v36(scene)

func _stabilize_player_hud_v36() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var text_paths: Array[NodePath] = [
        NodePath("HUD/Objective"),
        NodePath("HUD/CaseFile"),
        NodePath("HUD/ShelterStatus"),
        NodePath("HUD/PanicLabel"),
        NodePath("HUD/InteractionHint"),
        NodePath("HUD/Controls"),
        NodePath("HUD/InventoryLabel")
    ]
    for path: NodePath in text_paths:
        var label: Label = player.get_node_or_null(path) as Label
        if label == null:
            continue
        if path == NodePath("HUD/InventoryLabel"):
            label.text = _localize_inventory(label.text)
        elif path == NodePath("HUD/Controls"):
            label.text = _localize_controls_text(label.text)
        elif path == NodePath("HUD/PanicLabel"):
            label.text = _localize_stat_line(label.text)
        else:
            label.text = localize_gameplay_text(label.text)

    var top_bar: Control = player.get_node_or_null("HUD/TopStatusBarV32") as Control
    if top_bar != null:
        var labels: Array[Node] = top_bar.find_children("*", "Label", true, false)
        for node: Node in labels:
            var stat_label: Label = node as Label
            if stat_label != null:
                stat_label.text = _localize_stat_line(stat_label.text)

func _stabilize_journal_v36() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var names: Array[String] = ["mission_label", "entry_heading", "entry_counter"]
    for property_name: String in names:
        var value: Variant = _safe_property_v36(journal, property_name)
        if not (value is Label):
            continue
        var label: Label = value as Label
        if property_name == "entry_heading":
            label.text = _localize_journal_heading(label.text)
        elif property_name == "entry_counter":
            label.text = _localize_entry_counter(label.text)
        else:
            label.text = localize_gameplay_text(label.text)

func _stabilize_forest_runtime_v36() -> void:
    var runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if runtime == null:
        return
    var weather_value: Variant = _safe_property_v36(runtime, "weather_label")
    if weather_value is Label:
        var weather_label: Label = weather_value as Label
        weather_label.text = _localize_dynamic_weather_v36(weather_label.text)
    var hunt_value: Variant = _safe_property_v36(runtime, "hunt_button")
    if hunt_value is Button:
        var hunt_button: Button = hunt_value as Button
        hunt_button.text = _localize_ui_exact(hunt_button.text)

func _localize_dynamic_weather_v36(text: String) -> String:
    var result: String = text
    # ForestSurvivalSystem currently writes Indonesian weather names directly.
    # Canonicalize first so EN mode is stable instead of waiting for a later pass.
    result = result.replace("CUACA ", "WEATHER ")
    result = result.replace("BASAH ", "WET ")
    result = result.replace("CERAH", "CLEAR")
    result = result.replace("BERAWAN", "CLOUDY")
    result = result.replace("HUJAN", "RAIN")
    result = result.replace("BADAI", "STORM")
    if language_code == "id":
        result = result.replace("WEATHER ", "CUACA ")
        result = result.replace("WET ", "BASAH ")
        result = result.replace("CLEAR", "CERAH")
        result = result.replace("CLOUDY", "BERAWAN")
        result = result.replace("RAIN", "HUJAN")
        result = result.replace("STORM", "BADAI")
    return result

func _stabilize_condition_runtime_v36() -> void:
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth == null:
        return
    var status_value: Variant = _safe_property_v36(depth, "status_label")
    if status_value is Label:
        var status: Label = status_value as Label
        var text: String = status.text
        text = text.replace("PENDARAHAN", "BLEEDING")
        text = text.replace("DARAH", "BLEED")
        text = text.replace("INFEKSI", "INFECTION")
        if language_code == "id":
            text = text.replace("BLEEDING", "PENDARAHAN")
            text = text.replace("BLEED", "DARAH")
            text = text.replace("INFECTION", "INFEKSI")
        status.text = text

func _stabilize_multiplayer_runtime_v36() -> void:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        var coop_names: Array[String] = ["downed_title", "downed_help"]
        for property_name: String in coop_names:
            var value: Variant = _safe_property_v36(coop, property_name)
            if value is Label:
                var label: Label = value as Label
                label.text = localize_gameplay_text(label.text)

    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    if polish == null:
        return
    var polish_names: Array[String] = ["teammate_label", "mission_label", "connection_label", "roster_label", "revive_label"]
    for property_name: String in polish_names:
        var value: Variant = _safe_property_v36(polish, property_name)
        if value is Label:
            var label: Label = value as Label
            label.text = localize_gameplay_text(label.text)

func _stabilize_frontend_status_v36() -> void:
    var front_end: Node = get_node_or_null("/root/FrontEndSystem")
    if front_end == null:
        return
    var status_value: Variant = _safe_property_v36(front_end, "status_label")
    if status_value is Label:
        var status: Label = status_value as Label
        status.text = _localize_status(status.text)

func _stabilize_ranger_menu_v36(scene: Node) -> void:
    var status: Label = scene.get_node_or_null("MenuLayer/Root/Status") as Label
    if status != null:
        status.text = _localize_status(status.text)
    var summary: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/SaveSummary") as Label
    if summary != null:
        summary.text = _localize_status(summary.text)

func _safe_property_v36(owner: Object, property_name: String) -> Variant:
    if owner == null:
        return null
    var properties: Array[Dictionary] = owner.get_property_list()
    for info: Dictionary in properties:
        if str(info.get("name", "")) == property_name:
            return owner.get(property_name)
    return null
