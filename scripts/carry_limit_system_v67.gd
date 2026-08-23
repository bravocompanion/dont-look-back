extends Node

# v0.67 replaces unique-slot and per-item stack limits with a deterministic
# weight budget derived entirely from inventory_counts. This keeps legacy saves
# and multiplayer inventory mirrors compatible: no serialized weight field is
# needed, and overweight legacy inventories are never deleted.

const MAX_CARRY_WEIGHT_KG: float = 32.0
const LOADED_RATIO: float = 0.70
const HEAVY_RATIO: float = 0.90
const OVERWEIGHT_RATIO: float = 1.00
const DEFAULT_ITEM_WEIGHT_KG: float = 0.25
const LEGACY_UNLIMITED_CAPACITY: int = 2147483647

const ITEM_WEIGHTS_KG: Dictionary = {
    "canned_food": 0.45,
    "bottled_water": 1.00,
    "dirty_water": 1.00,
    "medkit": 1.25,
    "bandage": 0.15,
    "flashlight_battery": 0.30,
    "generator_fuel": 5.00,
    "firewood_bundle": 3.50,
    "wood": 0.75,
    "cloth": 0.12,
    "scrap": 0.55,
    "plastic_sheet": 0.30,
    "rubber": 0.25,
    "electronics": 0.35,
    "lead_plate": 1.80,
    "copper_wire": 0.40,
    "filter": 0.80,
    "arrow": 0.07,
    "raw_meat": 0.65,
    "cooked_meat": 0.60,
    "raw_fish": 0.50,
    "cooked_fish": 0.45,
    "hide": 0.90,
    "bone": 0.30,
    "animal_fat": 0.35,
    "raincoat": 1.10,
    "radiation_suit": 6.00,
    "hunting_bow": 1.30,
    "hunting_knife": 0.40,
    "fishing_rod": 1.00
}

# Objective/evidence progression is stored by dedicated systems rather than the
# physical expedition pack. These compatibility ids remain weightless if an old
# save or future bridge temporarily exposes them through inventory_counts.
const WEIGHTLESS_ITEMS: Dictionary = {
    "evidence": true,
    "investigation_evidence": true,
    "research_evidence": true,
    "quest_item": true,
    "objective_item": true
}

var refresh_timer_v67: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    refresh_timer_v67 -= delta
    if refresh_timer_v67 > 0.0:
        return
    refresh_timer_v67 = 0.20

    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        prepare_player_v67(player)
        _update_weight_indicator_v67(player)

func prepare_player_v67(player: CharacterBody3D) -> void:
    if player == null:
        return
    # Player.add_item() still contains the historical unique-type slot check.
    # Raising that obsolete capacity here removes it from gameplay without
    # changing save schema or duplicating the Player script across four maps.
    player.set("inventory_capacity", LEGACY_UNLIMITED_CAPACITY)

func get_item_weight(item_id: String) -> float:
    if bool(WEIGHTLESS_ITEMS.get(item_id, false)):
        return 0.0
    return maxf(0.0, float(ITEM_WEIGHTS_KG.get(item_id, DEFAULT_ITEM_WEIGHT_KG)))

func get_item_count(player: CharacterBody3D, item_id: String) -> int:
    if player == null:
        return 0
    var counts_value: Variant = player.get("inventory_counts")
    if not (counts_value is Dictionary):
        return 0
    return maxi(0, int(Dictionary(counts_value).get(item_id, 0)))

func get_weight_from_counts_v67(counts: Dictionary) -> float:
    var total: float = 0.0
    for key_variant: Variant in counts.keys():
        var item_id: String = str(key_variant)
        var amount: int = maxi(0, int(counts.get(key_variant, 0)))
        total += get_item_weight(item_id) * float(amount)
    return maxf(0.0, total)

func get_current_weight(player: CharacterBody3D) -> float:
    if player == null:
        return 0.0
    var counts_value: Variant = player.get("inventory_counts")
    if not (counts_value is Dictionary):
        return 0.0
    return get_weight_from_counts_v67(Dictionary(counts_value))

func get_max_weight(_player: CharacterBody3D = null) -> float:
    return MAX_CARRY_WEIGHT_KG

func get_remaining_weight(player: CharacterBody3D) -> float:
    return maxf(0.0, MAX_CARRY_WEIGHT_KG - get_current_weight(player))

func get_weight_ratio(player: CharacterBody3D) -> float:
    return get_current_weight(player) / MAX_CARRY_WEIGHT_KG if MAX_CARRY_WEIGHT_KG > 0.0 else 0.0

func get_encumbrance_status(player: CharacterBody3D) -> String:
    return get_encumbrance_status_for_weight_v67(get_current_weight(player))

func get_encumbrance_status_for_weight_v67(weight_kg: float) -> String:
    var ratio: float = weight_kg / MAX_CARRY_WEIGHT_KG if MAX_CARRY_WEIGHT_KG > 0.0 else 0.0
    if ratio > OVERWEIGHT_RATIO + 0.0001:
        return "OVERWEIGHT"
    if ratio > HEAVY_RATIO + 0.0001:
        return "HEAVY"
    if ratio > LOADED_RATIO + 0.0001:
        return "LOADED"
    return "NORMAL"

func get_movement_penalties_v67(player: CharacterBody3D) -> Dictionary:
    var status: String = get_encumbrance_status(player)
    match status:
        "LOADED":
            return {
                "status": status,
                "speed_multiplier": 1.0,
                "sprint_drain_multiplier": 1.15,
                "stamina_regen_multiplier": 0.90,
                "sprint_allowed": true
            }
        "HEAVY":
            return {
                "status": status,
                "speed_multiplier": 0.92,
                "sprint_drain_multiplier": 1.35,
                "stamina_regen_multiplier": 0.75,
                "sprint_allowed": true
            }
        "OVERWEIGHT":
            return {
                "status": status,
                "speed_multiplier": 0.78,
                "sprint_drain_multiplier": 1.0,
                "stamina_regen_multiplier": 1.0,
                "sprint_allowed": false
            }
    return {
        "status": "NORMAL",
        "speed_multiplier": 1.0,
        "sprint_drain_multiplier": 1.0,
        "stamina_regen_multiplier": 1.0,
        "sprint_allowed": true
    }

func can_accept_item(player: CharacterBody3D, item_id: String, amount: int = 1) -> bool:
    if player == null or amount <= 0:
        return false
    prepare_player_v67(player)
    var current: float = get_current_weight(player)
    var incoming: float = get_item_weight(item_id) * float(amount)
    if incoming <= 0.0001:
        return true
    if current > MAX_CARRY_WEIGHT_KG + 0.0001:
        return false
    return current + incoming <= MAX_CARRY_WEIGHT_KG + 0.0001

func can_accept_bundle(player: CharacterBody3D, bundle: Dictionary) -> bool:
    if player == null:
        return false
    prepare_player_v67(player)
    var current: float = get_current_weight(player)
    if current > MAX_CARRY_WEIGHT_KG + 0.0001:
        return false
    var incoming: float = 0.0
    for key_variant: Variant in bundle.keys():
        var item_id: String = str(key_variant)
        var amount: int = maxi(0, int(bundle.get(key_variant, 0)))
        incoming += get_item_weight(item_id) * float(amount)
    return current + incoming <= MAX_CARRY_WEIGHT_KG + 0.0001

func can_accept_transaction(player: CharacterBody3D, removals: Dictionary, additions: Dictionary) -> bool:
    if player == null:
        return false
    prepare_player_v67(player)
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
    if final_weight <= MAX_CARRY_WEIGHT_KG + 0.0001:
        return true
    # Legacy saves may start overweight. A transaction that strictly reduces
    # carried weight is always allowed so the player can recover naturally.
    return current > MAX_CARRY_WEIGHT_KG + 0.0001 and final_weight < current - 0.0001

func grant_item(player: CharacterBody3D, item_id: String, display_name: String, amount: int = 1) -> bool:
    if player == null or amount <= 0 or not player.has_method("add_item") or not player.has_method("remove_item"):
        return false
    prepare_player_v67(player)
    if not can_accept_item(player, item_id, amount):
        return false

    var granted: int = 0
    for _index: int in range(amount):
        if not bool(player.call("add_item", item_id, display_name)):
            for _refund_index: int in range(granted):
                player.call("remove_item", item_id)
            return false
        granted += 1
    return true

# Compatibility API retained for old callers/UI. Stack count itself is no
# longer a gameplay restriction; weight is the only carry constraint.
func get_stack_limit(_item_id: String) -> int:
    return LEGACY_UNLIMITED_CAPACITY

func remaining_stack(_player: CharacterBody3D, _item_id: String) -> int:
    return LEGACY_UNLIMITED_CAPACITY

func stack_status(player: CharacterBody3D, item_id: String) -> String:
    return "%.1f / %.1f kg; +%.2f kg" % [
        get_current_weight(player),
        MAX_CARRY_WEIGHT_KG,
        get_item_weight(item_id)
    ]

func get_weight_contract_v67() -> Dictionary:
    return {
        "max_weight_kg": MAX_CARRY_WEIGHT_KG,
        "loaded_ratio": LOADED_RATIO,
        "heavy_ratio": HEAVY_RATIO,
        "overweight_ratio": OVERWEIGHT_RATIO,
        "unique_type_limit_enabled": false,
        "stack_limit_enabled": false,
        "weight_derived_from_inventory_counts": true,
        "legacy_overweight_items_deleted": false,
        "equipment_counts_toward_weight": true,
        "default_unknown_item_weight_kg": DEFAULT_ITEM_WEIGHT_KG
    }

func _update_weight_indicator_v67(player: CharacterBody3D) -> void:
    var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return
    var label: Label = hud.get_node_or_null("CarryWeightStatusV67") as Label
    if label == null:
        label = Label.new()
        label.name = "CarryWeightStatusV67"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_size_override("font_size", 14)
        hud.add_child(label)

    var status: String = get_encumbrance_status(player)
    label.visible = status != "NORMAL"
    if not label.visible:
        return

    var current: float = get_current_weight(player)
    var viewport_width: float = player.get_viewport().get_visible_rect().size.x
    if viewport_width < 800.0:
        label.position = Vector2(maxf(8.0, viewport_width - 190.0), 74.0)
        label.size = Vector2(176.0, 28.0)
        label.text = "%.1f/32kg  %s" % [current, status]
    else:
        label.position = Vector2(maxf(8.0, viewport_width - 300.0), 92.0)
        label.size = Vector2(270.0, 30.0)
        label.text = "%s  •  %.1f / 32.0 kg" % [status, current]
