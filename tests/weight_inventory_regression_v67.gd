extends SceneTree

class MockPlayer:
    extends CharacterBody3D
    var inventory_names: Dictionary = {}
    var inventory_counts: Dictionary = {}
    var inventory_capacity: int = 8

    func add_item(item_id: String, display_name: String) -> bool:
        if inventory_names.has(item_id):
            inventory_counts[item_id] = int(inventory_counts.get(item_id, 0)) + 1
            return true
        if inventory_names.size() >= inventory_capacity:
            return false
        inventory_names[item_id] = display_name
        inventory_counts[item_id] = 1
        return true

    func remove_item(item_id: String) -> bool:
        var count: int = int(inventory_counts.get(item_id, 0))
        if count <= 0:
            return false
        count -= 1
        if count <= 0:
            inventory_counts.erase(item_id)
            inventory_names.erase(item_id)
        else:
            inventory_counts[item_id] = count
        return true

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[WEIGHT V67] Starting weight inventory regression...")

    var carry_script: Script = load("res://scripts/carry_limit_system_v67.gd") as Script
    var movement_script: Script = load("res://scripts/movement_system_v42.gd") as Script
    var crafting_script: Script = load("res://scripts/crafting_system_v55.gd") as Script
    var stash_script: Script = load("res://scripts/stash_menu_system_v55.gd") as Script
    var inventory_script: Script = load("res://scripts/inventory_menu_system_v56.gd") as Script
    if carry_script == null or movement_script == null or crafting_script == null or stash_script == null or inventory_script == null:
        _fail("one or more v0.67 scripts failed to load")
        _finish()
        return

    var carry: Node = carry_script.new() as Node
    var movement: Node = movement_script.new() as Node
    var crafting: Node = crafting_script.new() as Node
    var stash: Node = stash_script.new() as Node
    if carry == null or movement == null or crafting == null or stash == null:
        _fail("one or more v0.67 runtime scripts could not instantiate")
        _finish()
        return

    var contract: Dictionary = Dictionary(carry.call("get_weight_contract_v67"))
    _expect_close(float(contract.get("max_weight_kg", 0.0)), 32.0, 0.001, "max carry weight must be 32 kg")
    _expect(not bool(contract.get("unique_type_limit_enabled", true)), "unique type limit must be disabled")
    _expect(not bool(contract.get("stack_limit_enabled", true)), "stack limit must be disabled")
    _expect(bool(contract.get("weight_derived_from_inventory_counts", false)), "weight must derive from inventory_counts")
    _expect(bool(contract.get("equipment_counts_toward_weight", false)), "equipment must count toward carry weight")

    var player: MockPlayer = MockPlayer.new()
    carry.call("prepare_player_v67", player)
    _expect(player.inventory_capacity > 1000000, "legacy Player unique-slot capacity was not neutralized")

    # More than the old arrow cap of 20 must work when weight allows it.
    _expect(bool(carry.call("grant_item", player, "arrow", "Arrow", 30)), "30 arrows should fit by weight")
    _expect(int(player.inventory_counts.get("arrow", 0)) == 30, "arrow count should reach 30")
    _expect_close(float(carry.call("get_current_weight", player)), 2.10, 0.001, "30 arrows should weigh 2.10 kg")

    # More than the historical 8 unique item types must also work.
    var unique_items: Array[String] = [
        "cloth", "scrap", "rubber", "electronics", "copper_wire",
        "bandage", "canned_food", "bottled_water", "hunting_knife"
    ]
    for item_id: String in unique_items:
        _expect(bool(carry.call("grant_item", player, item_id, item_id, 1)), "failed to grant unique item %s" % item_id)
    _expect(player.inventory_names.size() >= 10, "inventory should allow more than 8 unique types")

    # Approved encumbrance thresholds.
    player.inventory_counts = {"generator_fuel": 4, "radiation_suit": 1} # 26 kg
    player.inventory_names = {"generator_fuel": "Fuel Can", "radiation_suit": "Radiation Suit"}
    _expect(str(carry.call("get_encumbrance_status", player)) == "LOADED", "26 kg should be LOADED")

    player.inventory_counts = {"generator_fuel": 5, "radiation_suit": 1} # 31 kg
    player.inventory_names = {"generator_fuel": "Fuel Can", "radiation_suit": "Radiation Suit"}
    _expect(str(carry.call("get_encumbrance_status", player)) == "HEAVY", "31 kg should be HEAVY")
    _expect(not bool(carry.call("can_accept_item", player, "bottled_water", 2)), "31 kg pack must reject 2 kg pickup")

    # Legacy overweight inventory remains intact but cannot gain positive weight.
    player.inventory_counts = {"generator_fuel": 7} # 35 kg
    player.inventory_names = {"generator_fuel": "Fuel Can"}
    _expect(str(carry.call("get_encumbrance_status", player)) == "OVERWEIGHT", "35 kg should be OVERWEIGHT")
    _expect(not bool(carry.call("can_accept_item", player, "arrow", 1)), "overweight player must reject additional physical items")
    _expect(bool(carry.call("can_accept_transaction", player, {"generator_fuel": 1}, {})), "overweight player must be allowed to reduce weight")
    _expect(not bool(carry.call("can_accept_transaction", player, {}, {"arrow": 1})), "overweight player must reject weight-increasing transaction")
    _expect(int(player.inventory_counts.get("generator_fuel", 0)) == 7, "weight checks must never delete legacy inventory")

    # Equipment is physical carry weight.
    _expect_close(float(carry.call("get_item_weight", "radiation_suit")), 6.0, 0.001, "radiation suit weight")
    _expect_close(float(carry.call("get_item_weight", "hunting_bow")), 1.3, 0.001, "hunting bow weight")

    var movement_contract: Dictionary = Dictionary(movement.call("get_weight_movement_contract_v67"))
    _expect_close(float(movement_contract.get("heavy_speed_multiplier", 0.0)), 0.92, 0.001, "HEAVY speed multiplier")
    _expect_close(float(movement_contract.get("overweight_speed_multiplier", 0.0)), 0.78, 0.001, "OVERWEIGHT speed multiplier")
    _expect(not bool(movement_contract.get("overweight_sprint_allowed", true)), "OVERWEIGHT sprint must be disabled")

    var crafting_contract: Dictionary = Dictionary(crafting.call("get_crafting_weight_contract_v67"))
    _expect(bool(crafting_contract.get("uses_net_weight", false)), "crafting must use net transaction weight")
    _expect(bool(crafting_contract.get("overweight_weight_reducing_recipe_allowed", false)), "overweight recovery crafting must be allowed")

    var stash_contract: Dictionary = Dictionary(stash.call("get_stash_weight_contract_v67"))
    _expect(bool(stash_contract.get("withdrawal_uses_weight_check", false)), "stash withdrawal must use weight check")
    _expect(not bool(stash_contract.get("stash_has_personal_32kg_limit", true)), "cabin stash must not use the personal 32 kg cap")

    carry.free()
    movement.free()
    crafting.free()
    stash.free()
    player.free()
    _finish()

func _expect(condition: bool, message: String) -> void:
    if not condition:
        _fail(message)

func _expect_close(actual: float, expected: float, epsilon: float, message: String) -> void:
    if absf(actual - expected) > epsilon:
        _fail("%s: got %.4f expected %.4f" % [message, actual, expected])

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[WEIGHT V67] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[WEIGHT V67] PASS — 32 kg weight inventory, no stack/type caps, encumbrance, crafting and stash contracts verified.")
        quit(0)
        return
    push_error("[WEIGHT V67] FAIL — %d issue(s)" % failures.size())
    quit(1)
