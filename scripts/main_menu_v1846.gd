extends "res://scripts/main_menu.gd"

const AUDIT_VERSION_TEXT: String = "v0.18.4.6"

func _ready() -> void:
    # Desktop menu input must remain real mouse input. If touch emulation was
    # enabled while testing mobile controls, an autoload could otherwise see a
    # synthetic InputEventScreenTouch before the GUI receives the mouse click.
    if not _mobile_platform():
        Input.emulate_touch_from_mouse = false

    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile != null and mobile.has_method("set_external_blocked"):
        mobile.call("set_external_blocked", true)

    super._ready()

    var version_label: Label = get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null:
        version_label.text = "%s  •  SURVIVAL HORROR" % AUDIT_VERSION_TEXT
