extends Node

const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"
const AUDIO_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const SEARCH_ROOTS: Array[String] = [
    "res://assets",
    "res://Assets",
    "res://audio",
    "res://Audio",
    "res://sounds",
    "res://Sounds",
    "res://sfx",
    "res://SFX",
    "res://music",
    "res://Music"
]

@export var music_volume_db: float = -16.0
@export var hurt_volume_db: float = -4.0
@export var monster_near_volume_db: float = -3.0
@export var monster_far_volume_db: float = -27.0
@export var monster_start_distance: float = 22.0
@export var monster_near_distance: float = 3.0
@export var music_monster_duck_db: float = 5.5
@export var interference_battery_far_volume_db: float = -9.0
@export var interference_battery_near_volume_db: float = -2.5

var music_player: AudioStreamPlayer
var hurt_player: AudioStreamPlayer
var monster_player: AudioStreamPlayer
var battery_player: AudioStreamPlayer

var music_stream: AudioStream
var hurt_stream: AudioStream
var monster_stream: AudioStream
var battery_stream: AudioStream

var tracked_player_id: int = 0
var last_health: float = 100.0
var player_grace_timer: float = 0.0
var asset_retry_timer: float = 0.0
var loaded_assets: bool = false
var reported_missing_assets: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_players()
    _load_audio_assets()

func _process(delta: float) -> void:
    asset_retry_timer = maxf(0.0, asset_retry_timer - delta)
    if not loaded_assets and asset_retry_timer <= 0.0:
        asset_retry_timer = 3.0
        _load_audio_assets()

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MAIN_MENU_SCENE_PATH:
        _release_player()
        _stop_gameplay_audio()
        return

    _ensure_music()

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        _release_player()
        _fade_monster_audio(delta, INF)
        _update_interference_battery_audio()
        return

    _track_player(player)
    player_grace_timer = maxf(0.0, player_grace_timer - delta)

    _update_hurt_audio(player)
    _update_interference_battery_audio()
    _update_monster_audio(player, delta)

func _build_players() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "Music"
    music_player.volume_db = music_volume_db
    add_child(music_player)

    hurt_player = AudioStreamPlayer.new()
    hurt_player.name = "Hurt"
    hurt_player.volume_db = hurt_volume_db
    add_child(hurt_player)

    monster_player = AudioStreamPlayer.new()
    monster_player.name = "MonsterProximity"
    monster_player.volume_db = monster_far_volume_db
    add_child(monster_player)

    battery_player = AudioStreamPlayer.new()
    battery_player.name = "FlashlightMonsterInterference"
    battery_player.volume_db = interference_battery_far_volume_db
    add_child(battery_player)

func _load_audio_assets() -> void:
    if music_stream == null:
        var found_music: AudioStream = _find_audio_stream("music")
        if found_music != null:
            music_stream = found_music
            music_player.stream = music_stream

    if hurt_stream == null:
        var found_hurt: AudioStream = _find_audio_stream("hurt")
        if found_hurt != null:
            hurt_stream = found_hurt
            hurt_player.stream = hurt_stream

    if monster_stream == null:
        var found_monster: AudioStream = _find_audio_stream("monster")
        if found_monster != null:
            monster_stream = found_monster
            monster_player.stream = monster_stream

    if battery_stream == null:
        var found_battery: AudioStream = _find_audio_stream("battery")
        if found_battery != null:
            battery_stream = found_battery
            battery_player.stream = battery_stream

    loaded_assets = music_stream != null and hurt_stream != null and monster_stream != null and battery_stream != null
    if not loaded_assets and not reported_missing_assets:
        reported_missing_assets = true
        print("DynamicAudioSystem: waiting for music/hurt/monster/battery audio under res://assets (wav/ogg/mp3).")

func _find_audio_stream(keyword: String) -> AudioStream:
    var candidates: Array[String] = []
    for root: String in SEARCH_ROOTS:
        _collect_audio_paths(root, candidates)
    candidates.sort()

    var keyword_lower: String = keyword.to_lower()
    var fallback_path: String = ""
    for path: String in candidates:
        var filename: String = path.get_file().get_basename().to_lower()
        if filename == keyword_lower:
            var exact_stream: AudioStream = load(path) as AudioStream
            if exact_stream != null:
                return exact_stream
        if fallback_path.is_empty() and filename.contains(keyword_lower):
            fallback_path = path

    if not fallback_path.is_empty():
        return load(fallback_path) as AudioStream
    return null

func _collect_audio_paths(root: String, output: Array[String]) -> void:
    var directory: DirAccess = DirAccess.open(root)
    if directory == null:
        return

    directory.list_dir_begin()
    var entry: String = directory.get_next()
    while not entry.is_empty():
        var is_directory: bool = directory.current_is_dir()
        if not entry.begins_with("."):
            var path: String = root.path_join(entry)
            if is_directory:
                _collect_audio_paths(path, output)
            elif _is_audio_path(path):
                output.append(path)
        entry = directory.get_next()
    directory.list_dir_end()

func _is_audio_path(path: String) -> bool:
    var extension: String = path.get_extension().to_lower()
    return AUDIO_EXTENSIONS.has(extension)

func _track_player(player: CharacterBody3D) -> void:
    var player_id: int = int(player.get_instance_id())
    if tracked_player_id == player_id:
        return
    tracked_player_id = player_id
    last_health = float(player.get("health"))
    player_grace_timer = 1.25

func _release_player() -> void:
    tracked_player_id = 0
    player_grace_timer = 0.0

func _ensure_music() -> void:
    if music_stream == null:
        return
    if music_player.stream != music_stream:
        music_player.stream = music_stream
    if not music_player.playing:
        music_player.volume_db = music_volume_db
        music_player.play()

func _update_hurt_audio(player: CharacterBody3D) -> void:
    var health: float = float(player.get("health"))
    var damage_taken: float = maxf(0.0, last_health - health)
    if player_grace_timer <= 0.0 and damage_taken >= 3.0 and hurt_stream != null:
        hurt_player.stop()
        hurt_player.pitch_scale = 0.96 + randf() * 0.08
        hurt_player.play()
    last_health = health

func _update_interference_battery_audio() -> void:
    if battery_player == null:
        return

    var flashlight_system: Node = get_node_or_null("/root/FlashlightMotionSystem")
    var active: bool = flashlight_system != null and flashlight_system.has_method("is_monster_interference_active") and bool(flashlight_system.call("is_monster_interference_active"))
    if not active or battery_stream == null:
        if battery_player.playing:
            battery_player.stop()
        return

    var strength: float = 0.0
    if flashlight_system.has_method("get_monster_interference_strength"):
        strength = clampf(float(flashlight_system.call("get_monster_interference_strength")), 0.0, 1.0)
    battery_player.volume_db = lerpf(interference_battery_far_volume_db, interference_battery_near_volume_db, strength)
    battery_player.pitch_scale = lerpf(0.96, 1.08, strength)
    if battery_player.stream != battery_stream:
        battery_player.stream = battery_stream
    if not battery_player.playing:
        battery_player.play()

func _update_monster_audio(player: CharacterBody3D, delta: float) -> void:
    var nearest_distance: float = _nearest_active_monster_distance(player.global_position)
    _fade_monster_audio(delta, nearest_distance)

func _fade_monster_audio(delta: float, nearest_distance: float) -> void:
    var has_near_monster: bool = nearest_distance <= monster_start_distance
    var threat: float = 0.0
    if has_near_monster:
        var denominator: float = maxf(0.1, monster_start_distance - monster_near_distance)
        threat = 1.0 - clampf((nearest_distance - monster_near_distance) / denominator, 0.0, 1.0)

    var target_monster_db: float = lerpf(monster_far_volume_db, monster_near_volume_db, threat)
    if monster_player != null:
        monster_player.volume_db = move_toward(monster_player.volume_db, target_monster_db, 22.0 * delta)
        if has_near_monster and monster_stream != null:
            if monster_player.stream != monster_stream:
                monster_player.stream = monster_stream
            if not monster_player.playing:
                monster_player.play()
        elif monster_player.playing:
            monster_player.volume_db = move_toward(monster_player.volume_db, -55.0, 28.0 * delta)
            if monster_player.volume_db <= -48.0:
                monster_player.stop()
                monster_player.volume_db = monster_far_volume_db

    if music_player != null:
        var target_music_db: float = music_volume_db - threat * music_monster_duck_db
        music_player.volume_db = move_toward(music_player.volume_db, target_music_db, 10.0 * delta)

func _nearest_active_monster_distance(origin: Vector3) -> float:
    var nearest: float = INF
    var seen_ids: Dictionary = {}

    var groups: Array[StringName] = [StringName("arc1_enemy"), StringName("arc1_warden"), StringName("darkness_creature")]
    for group_name: StringName in groups:
        for candidate: Node in get_tree().get_nodes_in_group(group_name):
            if not (candidate is Node3D):
                continue
            var monster: Node3D = candidate as Node3D
            if not is_instance_valid(monster) or not monster.visible:
                continue
            var instance_id: int = int(monster.get_instance_id())
            if seen_ids.has(instance_id):
                continue
            seen_ids[instance_id] = true
            nearest = minf(nearest, origin.distance_to(monster.global_position))

    var scene: Node = get_tree().current_scene
    if scene != null:
        var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D
        if tenant != null and is_instance_valid(tenant) and tenant.visible:
            nearest = minf(nearest, origin.distance_to(tenant.global_position))

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        var dark_value: Variant = coop.get("dark_node")
        if dark_value is Node3D:
            var shared_darkness: Node3D = dark_value
            if is_instance_valid(shared_darkness) and shared_darkness.visible:
                nearest = minf(nearest, origin.distance_to(shared_darkness.global_position))

    return nearest

func _stop_gameplay_audio() -> void:
    if music_player != null and music_player.playing:
        music_player.stop()
    if monster_player != null and monster_player.playing:
        monster_player.stop()
    if hurt_player != null and hurt_player.playing:
        hurt_player.stop()
    if battery_player != null and battery_player.playing:
        battery_player.stop()
