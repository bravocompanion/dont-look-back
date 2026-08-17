extends Node

@export var movement_panic_threshold: float = 0.15
@export var movement_full_panic_speed: float = 6.6
@export var movement_panic_gain_per_second: float = 7.5
@export var calm_panic_decay_per_second: float = 5.0

var configured_panic_id: int = 0
var probe_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -5

func _process(delta: float) -> void:
    probe_timer -= delta
    if probe_timer > 0.0:
        return
    probe_timer = 0.35

    var panic: Node = get_node_or_null("/root/PanicInputSystem")
    if panic == null:
        configured_panic_id = 0
        return

    var panic_id: int = int(panic.get_instance_id())
    if panic_id == configured_panic_id and _settings_match(panic):
        return

    configured_panic_id = panic_id
    panic.set("movement_panic_threshold", movement_panic_threshold)
    panic.set("movement_full_panic_speed", movement_full_panic_speed)
    panic.set("movement_panic_gain_per_second", movement_panic_gain_per_second)
    panic.set("calm_panic_decay_per_second", calm_panic_decay_per_second)

func _settings_match(panic: Node) -> bool:
    return (
        is_equal_approx(float(panic.get("movement_panic_threshold")), movement_panic_threshold)
        and is_equal_approx(float(panic.get("movement_full_panic_speed")), movement_full_panic_speed)
        and is_equal_approx(float(panic.get("movement_panic_gain_per_second")), movement_panic_gain_per_second)
        and is_equal_approx(float(panic.get("calm_panic_decay_per_second")), calm_panic_decay_per_second)
    )
