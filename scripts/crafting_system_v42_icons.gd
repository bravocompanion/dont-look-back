extends "res://scripts/crafting_system_v41_safe.gd"

func _build_ui() -> void:
    super._build_ui()
    call_deferred("_apply_recipe_icons")

func _refresh_recipe_buttons() -> void:
    super._refresh_recipe_buttons()
    _apply_recipe_icons()

func _apply_recipe_icons() -> void:
    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    if registry == null or not registry.has_method("get_recipe_icon"):
        return

    for recipe_id: String in RECIPE_IDS:
        var button: Button = recipe_buttons.get(recipe_id) as Button
        if button == null:
            continue
        var texture: Texture2D = registry.call("get_recipe_icon", recipe_id) as Texture2D
        if texture == null:
            continue
        button.icon = texture
        button.expand_icon = true
        button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        button.tooltip_text = "%s — %s" % [_recipe_name(recipe_id), _recipe_cost_text(recipe_id)]
