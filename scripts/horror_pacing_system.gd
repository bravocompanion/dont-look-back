extends Node

# v0.58 high-level horror budget. This does not drive AI movement; it only
# serializes major co-op encounters and grants a recovery window after them.

@export var tenant_recovery_seconds: float = 26.0
@export var darkness_recovery_seconds: float = 16.0

var current_major_threat: String = ""
var recovery_remaining: float = 0.0
var recovery_source: String = ""
var last_scene_path: String = ""

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    var scene_path: String = scene.scene_file_path if scene != null else ""
    if scene_path != last_scene_path:
        last_scene_path = scene_path
        current_major_threat = ""
        recovery_remaining = 0.0
        recovery_source = ""
        return
    recovery_remaining = maxf(0.0, recovery_remaining - delta)
    if recovery_remaining <= 0.0:
        recovery_source = ""

func can_start_major_threat(threat_id: String) -> bool:
    if threat_id.is_empty():
        return false
    if not current_major_threat.is_empty() and current_major_threat != threat_id:
        return false
    return recovery_remaining <= 0.0

func begin_major_threat(threat_id: String) -> bool:
    if not can_start_major_threat(threat_id):
        return false
    current_major_threat = threat_id
    recovery_remaining = 0.0
    recovery_source = ""
    return true

func end_major_threat(threat_id: String, recovery_seconds: float = -1.0) -> void:
    if current_major_threat != threat_id:
        return
    current_major_threat = ""
    recovery_source = threat_id
    var duration: float = recovery_seconds
    if duration < 0.0:
        duration = tenant_recovery_seconds if threat_id == "tenant" else darkness_recovery_seconds
    recovery_remaining = maxf(recovery_remaining, maxf(0.0, duration))

func force_recovery(seconds: float, source: String = "system") -> void:
    current_major_threat = ""
    recovery_source = source
    recovery_remaining = maxf(recovery_remaining, maxf(0.0, seconds))

func is_recovering() -> bool:
    return recovery_remaining > 0.0

func get_pacing_state() -> String:
    if not current_major_threat.is_empty():
        return "HUNT:%s" % current_major_threat.to_upper()
    if recovery_remaining > 0.0:
        return "RECOVERY"
    return "AVAILABLE"
