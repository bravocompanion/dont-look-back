extends StaticBody3D

@export var circuit_id: String = "upper"
@export var display_name: String = "UPPER SHAFT"

func _ready() -> void:
    add_to_group("mine_power_console")

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/MinePowerSystem")
    if system == null:
        return "Power routing unavailable"
    var active: String = str(system.get("current_circuit"))
    if active == circuit_id:
        return "%s POWER — ACTIVE" % display_name
    return "Route power to %s" % display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/MinePowerSystem")
    if system != null and system.has_method("request_select_circuit"):
        system.call("request_select_circuit", circuit_id)
