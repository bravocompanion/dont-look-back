extends "res://scripts/forest_survival_system_v48.gd"

const WILDLIFE_V49_SCRIPT_PATH: String = "res://scripts/wildlife_animal_v49.gd"

const DRAW_AUDIO_PATHS: Array[String] = [
    "res://assets/audio/draw.mp3",
    "res://draw.mp3"
]
const SHOOT_AUDIO_PATHS: Array[String] = [
    "res://assets/audio/shoot.mp3",
    "res://shoot.mp3"
]
const IMPACT_AUDIO_PATHS: Array[String] = [
    "res://assets/audio/impact.mp3",
    "res://impact.mp3"
]

@export var bow_draw_audio_db: float = -5.0
@export var bow_shoot_audio_db: float = -3.0
@export var bow_impact_audio_db: float = -4.0
@export var bow_impact_audio_max_distance: float = 34.0

var draw_audio: AudioStreamPlayer
var shoot_audio: AudioStreamPlayer
var impact_stream: AudioStream

func _ready() -> void:
    super._ready()
    wildlife_script = load(WILDLIFE_V49_SCRIPT_PATH) as Script
    call_deferred("_setup_arrow_audio")

func _begin_bow_draw() -> void:
    var was_drawing: bool = bow_drawing
    super._begin_bow_draw()
    if not was_drawing and bow_drawing:
        _play_draw_audio_once()

func _release_bow_draw() -> void:
    if not bow_drawing:
        return
    var cooldown_before: float = bow_cooldown
    super._release_bow_draw()
    if bow_cooldown > cooldown_before + 0.001:
        _play_shoot_audio()

func _finish_bow_draw_visuals() -> void:
    _stop_draw_audio()
    super._finish_bow_draw_visuals()

func _broadcast_arrow_impact(
    projectile_id: int,
    impact_position: Vector3,
    impact_normal: Vector3,
    can_recover: bool
) -> void:
    super._broadcast_arrow_impact(projectile_id, impact_position, impact_normal, can_recover)
    if _network_online():
        _play_arrow_impact_audio_remote.rpc(impact_position)
    else:
        _play_arrow_impact_audio_remote(impact_position)

@rpc("authority", "call_local", "unreliable", 39)
func _play_arrow_impact_audio_remote(impact_position: Vector3) -> void:
    _play_impact_audio_at(impact_position)

func _setup_arrow_audio() -> void:
    if not is_inside_tree():
        return

    draw_audio = AudioStreamPlayer.new()
    draw_audio.name = "BowDrawAudioV49"
    draw_audio.volume_db = bow_draw_audio_db
    draw_audio.stream = _load_first_audio(DRAW_AUDIO_PATHS)
    add_child(draw_audio)

    shoot_audio = AudioStreamPlayer.new()
    shoot_audio.name = "BowShootAudioV49"
    shoot_audio.volume_db = bow_shoot_audio_db
    shoot_audio.stream = _load_first_audio(SHOOT_AUDIO_PATHS)
    add_child(shoot_audio)

    impact_stream = _load_first_audio(IMPACT_AUDIO_PATHS)

func _play_draw_audio_once() -> void:
    if draw_audio == null or draw_audio.stream == null:
        return
    draw_audio.stop()

    # Stretch one draw clip so its playback duration matches the time required to
    # reach 100% draw power. The clip is never looped/retriggered while holding.
    var clip_length: float = draw_audio.stream.get_length()
    var target_length: float = maxf(0.10, bow_full_draw_seconds)
    draw_audio.pitch_scale = clampf(clip_length / target_length, 0.20, 4.0) if clip_length > 0.01 else 1.0
    draw_audio.play()

func _stop_draw_audio() -> void:
    if draw_audio != null and draw_audio.playing:
        draw_audio.stop()

func _play_shoot_audio() -> void:
    if shoot_audio == null or shoot_audio.stream == null:
        return
    shoot_audio.pitch_scale = 1.0
    shoot_audio.stop()
    shoot_audio.play()

func _play_impact_audio_at(world_position: Vector3) -> void:
    if impact_stream == null:
        return
    var scene: Node = get_tree().current_scene
    if scene == null or not (scene is Node3D):
        return

    var emitter: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
    emitter.name = "ArrowImpactAudioV49"
    emitter.stream = impact_stream
    emitter.volume_db = bow_impact_audio_db
    emitter.max_distance = bow_impact_audio_max_distance
    emitter.unit_size = 4.0
    scene.add_child(emitter)
    emitter.global_position = world_position
    emitter.finished.connect(emitter.queue_free)
    emitter.play()

func _load_first_audio(paths: Array[String]) -> AudioStream:
    for path: String in paths:
        if not ResourceLoader.exists(path):
            continue
        var stream: AudioStream = load(path) as AudioStream
        if stream != null:
            return stream
    return null
