extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const FOREST_NIGHT_STREAM_PATH: String = "res://assets/audio/forest_night.mp3"
const NIGHT_START_MINUTES: float = 20.0 * 60.0
const NIGHT_END_MINUTES: float = 5.0 * 60.0
const FADE_SECONDS: float = 2.0
const SILENT_DB: float = -80.0
const TARGET_DB: float = -7.0

var ambience_player: AudioStreamPlayer
var fade_tween: Tween
var requested_active: bool = false
var stream_loaded: bool = false
var warned_missing_stream: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_player()

func _process(_delta: float) -> void:
    var should_be_active: bool = _should_play_forest_night()
    if should_be_active == requested_active:
        return
    requested_active = should_be_active
    if requested_active:
        _fade_in()
    else:
        _fade_out()

func _ensure_player() -> void:
    if ambience_player != null and is_instance_valid(ambience_player):
        return
    ambience_player = AudioStreamPlayer.new()
    ambience_player.name = "ForestNightAmbience"
    ambience_player.volume_db = SILENT_DB
    ambience_player.autoplay = false
    ambience_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
    add_child(ambience_player)

func _ensure_stream() -> bool:
    _ensure_player()
    if stream_loaded and ambience_player.stream != null:
        return true
    if not ResourceLoader.exists(FOREST_NIGHT_STREAM_PATH):
        if not warned_missing_stream:
            warned_missing_stream = true
            push_warning("ForestNightAudioSystem: missing %s" % FOREST_NIGHT_STREAM_PATH)
        return false

    var loaded_stream: AudioStream = load(FOREST_NIGHT_STREAM_PATH) as AudioStream
    if loaded_stream == null:
        if not warned_missing_stream:
            warned_missing_stream = true
            push_warning("ForestNightAudioSystem: failed to load %s" % FOREST_NIGHT_STREAM_PATH)
        return false

    var stream_copy: AudioStream = loaded_stream.duplicate(true) as AudioStream
    if stream_copy is AudioStreamMP3:
        var mp3_stream: AudioStreamMP3 = stream_copy as AudioStreamMP3
        mp3_stream.loop = true
    ambience_player.stream = stream_copy
    stream_loaded = true
    warned_missing_stream = false
    return true

func _should_play_forest_night() -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        return false

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null or not outside.has_method("get_time_minutes"):
        return false

    var minutes: float = fmod(float(outside.call("get_time_minutes")), 1440.0)
    if minutes < 0.0:
        minutes += 1440.0
    return minutes >= NIGHT_START_MINUTES or minutes < NIGHT_END_MINUTES

func _fade_in() -> void:
    if not _ensure_stream():
        return
    _kill_fade()
    if not ambience_player.playing:
        ambience_player.volume_db = SILENT_DB
        ambience_player.play()
    fade_tween = create_tween()
    fade_tween.tween_property(ambience_player, "volume_db", TARGET_DB, FADE_SECONDS)

func _fade_out() -> void:
    if ambience_player == null or not is_instance_valid(ambience_player):
        return
    if not ambience_player.playing:
        ambience_player.volume_db = SILENT_DB
        return
    _kill_fade()
    fade_tween = create_tween()
    fade_tween.tween_property(ambience_player, "volume_db", SILENT_DB, FADE_SECONDS)
    fade_tween.tween_callback(Callable(self, "_finish_fade_out"))

func _finish_fade_out() -> void:
    if requested_active:
        return
    if ambience_player != null and is_instance_valid(ambience_player):
        ambience_player.stop()
        ambience_player.volume_db = SILENT_DB

func _kill_fade() -> void:
    if fade_tween != null and fade_tween.is_valid():
        fade_tween.kill()
    fade_tween = null
