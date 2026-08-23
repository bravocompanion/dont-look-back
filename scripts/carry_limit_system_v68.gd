extends "res://scripts/carry_limit_system_v67.gd"

func get_max_weight(_player: CharacterBody3D = null) -> float:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    var bonus: float = float(progression.call("get_max_carry_bonus_v68")) if progression != null and progression.has_method("get_max_carry_bonus_v68") else 0.0
    return MAX_CARRY_WEIGHT_KG + maxf(0.0, bonus)

func get_remaining_weight(player: CharacterBody3D) -> float:
    return maxf(0.0, get_max_weight(player) - get_current_weight(player))

func get_weight_ratio(player: CharacterBody3D) -> float:
    var maximum: float = get_max_weight(player)
    return get_current_weight(player) / maximum if maximum > 0.0 else 0.0

func get_encumbrance_status(player: CharacterBody3D) -> String:
    var maximum: float = get_max_weight(player)
    var ratio: float = get_current_weight(player) / maximum if maximum > 0.0 else 0.0
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    var loaded_ratio: float = float(progression.call("get_loaded_ratio_v68")) if progression != null and progression.has_method("get_loaded_ratio_v68") else LOADED_RATIO
    if ratio > OVERWEIGHT_RATIO + 0.0001:
        return "OVERWEIGHT"
    if ratio > HEAVY_RATIO + 0.0001:
        return "HEAVY"
    if ratio > loaded_ratio + 0.0001:
        return "LOADED"
    return "NORMAL"

func can_accept_item(player: CharacterBody3D, item_id: String, amount: int = 1) -> bool:
    if player == null or amount <= 0:
        return false
    prepare_player_v67(player)
    var maximum: float = get_max_weight(player)
    var current: float = get_current_weight(player)
    var incoming: float = get_item_weight(item_id) * float(amount)
    if incoming <= 0.0001:
        return true
    if current > maximum + 0.0001:
        return false
    return current + incoming <= maximum + 0.0001

func can_accept_bundle(player: CharacterBody3D, bundle: Dictionary) -> bool:
    if player == null:
        return false
    prepare_player_v67(player)
    var maximum: float = get_max_weight(player)
    var current: float = get_current_weight(player)
    if current > maximum + 0.0001:
        return false
    var incoming: float = 0.0
    for key_variant: Variant in bundle.keys():
        var item_id: String = str(key_variant)
        var amount: int = maxi(0, int(bundle.get(key_variant, 0)))
        incoming += get_item_weight(item_id) * float(amount)
    return current + incoming <= maximum + 0.0001

func can_accept_transaction(player: CharacterBody3D, removals: Dictionary, additions: Dictionary) -> bool:
    if player == null:
        return false
    prepare_player_v67(player)
    var maximum: float = get_max_weight(player)
    var current: float = get_current_weight(player)
    var removal_weight: float = 0.0
    for key_variant: Variant in removals.keys():
        var item_id: String = str(key_variant)
        var requested: int = maxi(0, int(removals.get(key_variant, 0)))
        var available: int = get_item_count(player, item_id)
        removal_weight += get_item_weight(item_id) * float(mini(requested, available))
    var addition_weight: float = 0.0
    for key_variant: Variant in additions.keys():
        var item_id: String = str(key_variant)
        var amount: int = maxi(0, int(additions.get(key_variant, 0)))
        addition_weight += get_item_weight(item_id) * float(amount)
    var final_weight: float = maxf(0.0, current - removal_weight + addition_weight)
    if final_weight <= maximum + 0.0001:
        return true
    return current > maximum + 0.0001 and final_weight < current - 0.0001

func stack_status(player: CharacterBody3D, item_id: String) -> String:
    return "%.1f / %.1f kg; +%.2f kg" % [get_current_weight(player), get_max_weight(player), get_item_weight(item_id)]

func get_weight_contract_v68() -> Dictionary:
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    var loaded_ratio: float = float(progression.call("get_loaded_ratio_v68")) if progression != null and progression.has_method("get_loaded_ratio_v68") else LOADED_RATIO
    return {
        "base_max_weight_kg": MAX_CARRY_WEIGHT_KG,
        "effective_max_weight_kg": get_max_weight(null),
        "loaded_ratio": loaded_ratio,
        "heavy_ratio": HEAVY_RATIO,
        "overweight_ratio": OVERWEIGHT_RATIO,
        "progression_bonus_enabled": true,
        "equipment_counts_toward_weight": true,
        "stack_limit_enabled": false,
        "unique_type_limit_enabled": false
    }

func _update_weight_indicator_v67(player: CharacterBody3D) -> void:
    super._update_weight_indicator_v67(player)
    var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return
    var label: Label = hud.get_node_or_null("CarryWeightStatusV67") as Label
    if label == null or not label.visible:
        return
    var status: String = get_encumbrance_status(player)
    var current: float = get_current_weight(player)
    var maximum: float = get_max_weight(player)
    var viewport_width: float = player.get_viewport().get_visible_rect().size.x
    if viewport_width < 800.0:
        label.text = "%.1f/%.1fkg  %s" % [current, maximum, status]
    else:
        label.text = "%s  •  %.1f / %.1f kg" % [status, current, maximum]
