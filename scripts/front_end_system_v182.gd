extends "res://scripts/front_end_system_v181.gd"

func _input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
            var crafting: Node = get_node_or_null("/root/CraftingSystem")
            if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
                if crafting.has_method("close_workbench"):
                    crafting.call("close_workbench")
                get_viewport().set_input_as_handled()
                return
    super._input(event)
