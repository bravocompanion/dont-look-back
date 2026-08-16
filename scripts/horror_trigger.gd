extends Area3D

@export var monster_path: NodePath
@export var objective_label_path: NodePath
@export var flicker_light_path: NodePath

var triggered: bool = false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
    if triggered or not body.is_in_group("player"):
        return

    triggered = true
    var objective: Label = get_node_or_null(objective_label_path) as Label
    if objective != null:
        objective.text = "The lights died behind you..."

    var light: Light3D = get_node_or_null(flicker_light_path) as Light3D
    if light != null:
        var flicker_delays: Array[float] = [0.10, 0.06, 0.14, 0.05, 0.18]
        for delay: float in flicker_delays:
            light.visible = not light.visible
            await get_tree().create_timer(delay).timeout
        light.visible = true

    await get_tree().create_timer(0.25).timeout

    # v0.24.2: this trigger is environmental only. The Tenant is no longer
    # spawned by corridor proximity; staying completely still for 2 seconds
    # is the encounter trigger handled by PanicTenantSystem.
    if objective != null:
        objective.text = "Move calmly. Sudden speed feeds PANIC. Do not stay still too long."
