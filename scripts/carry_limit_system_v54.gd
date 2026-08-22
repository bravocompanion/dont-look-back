extends Node

# v0.54 expedition carry limits. Inventory capacity still limits unique item
# types, while these limits stop one slot from carrying an unlimited stack.
const DEFAULT_STACK_LIMIT: int = 99
const STACK_LIMITS: Dictionary = {
    "canned_food": 5,
    "bottled_water": 4,
    "dirty_water": 3,
    "medkit": 2,
    "bandage": 4,
    "flashlight_battery": 3,
    "generator_fuel": 2,
    "firewood_bundle": 4,
    "wood": 10,
    "cloth": 10,
    "scrap": 12,
    "plastic_sheet": 8,
    "rubber": 8,
    "electronics": 8,
    "lead_plate": 8,
    "copper_wire": 8,
    "filter": 6,
    "arrow": 20,
    "raw_meat": 4,
    "cooked_meat": 4,
    "raw_fish": 4,
    "cooked_fish": 4,
    "hide": 6,
    "bone": 8,
    "animal_fat": 6,
    "raincoat": 1,
    "radiation_suit": 1,
    "hunting_bow": 1,
    "hunting_knife": 1,
    "fishing_rod": 1
}

func get_stack_limit(item_id: String) -> int:
    return maxi(1, int(STACK_LIMITS.get(item_id, DEFAULT_STACK_LIMIT)))

func get_item_count(player: CharacterBody3D, item_id: String) -> int:
    if player == null:
        return 0
    var counts_value: Variant = player.get("inventory_counts")
    if not (counts_value is Dictionary):
        return 0
    return int((counts_value as Dictionary).get(item_id, 0))

func remaining_stack(player: CharacterBody3D, item_id: String) -> int:
    return maxi(0, get_stack_limit(item_id) - get_item_count(player, item_id))

func can_accept_item(player: CharacterBody3D, item_id: String, amount: int = 1) -> bool:
    if player == null or amount <= 0:
        return false
    var current: int = get_item_count(player, item_id)
    if current + amount > get_stack_limit(item_id):
        return false
    if current > 0:
        return true

    var names_value: Variant = player.get("inventory_names")
    if not (names_value is Dictionary):
        return false
    var names: Dictionary = names_value
    var capacity: int = maxi(1, int(player.get("inventory_capacity")))
    return names.size() < capacity

func can_accept_bundle(player: CharacterBody3D, bundle: Dictionary) -> bool:
    if player == null:
        return false

    var names_value: Variant = player.get("inventory_names")
    if not (names_value is Dictionary):
        return false
    var names: Dictionary = names_value
    var capacity: int = maxi(1, int(player.get("inventory_capacity")))
    var new_types: int = 0

    for key_value: Variant in bundle.keys():
        var item_id: String = str(key_value)
        var amount: int = int(bundle.get(key_value, 0))
        if amount <= 0:
            continue
        if get_item_count(player, item_id) + amount > get_stack_limit(item_id):
            return false
        if not names.has(item_id):
            new_types += 1

    return names.size() + new_types <= capacity

func grant_item(player: CharacterBody3D, item_id: String, display_name: String, amount: int = 1) -> bool:
    if player == null or not player.has_method("add_item") or not player.has_method("remove_item"):
        return false
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

func stack_status(player: CharacterBody3D, item_id: String) -> String:
    return "%d/%d" % [get_item_count(player, item_id), get_stack_limit(item_id)]
