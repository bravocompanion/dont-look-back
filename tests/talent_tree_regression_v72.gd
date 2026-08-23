extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v72")

func _run_v72() -> void:
    await process_frame
    await process_frame

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    _check(progression != null, "ProgressionSystem autoload exists")
    if progression == null:
        _finish_v72()
        return

    _check(progression.has_method("get_talent_tree_contract_v72"), "v0.72 talent tree contract exists")
    _check(progression.has_method("get_talent_tree_names_v72"), "tree names API exists")
    _check(progression.has_method("get_talent_tree_tiers_v72"), "tree tiers API exists")
    _check(progression.has_method("get_talent_tree_node_state_v72"), "tree node-state API exists")
    _check(progression.has_method("can_unlock_talent_v72"), "tree unlock-state API exists")

    var contract: Dictionary = Dictionary(progression.call("get_talent_tree_contract_v72"))
    _check(bool(contract.get("visual_tree_not_list", false)), "talents are represented as a tree contract")
    _check(int(contract.get("tree_count", 0)) == 4, "four specialization trees retained")
    _check(not bool(contract.get("save_schema_changed", true)), "save schema unchanged")
    _check(not bool(contract.get("profile_format_changed", true)), "profile format unchanged")
    _check(not bool(contract.get("network_authority_changed", true)), "network authority unchanged")
    _check(bool(contract.get("mobile_vertical_tree", false)), "mobile vertical tree supported")
    _check(bool(contract.get("desktop_horizontal_tree", false)), "desktop horizontal tree supported")

    var tree_names: Array = Array(progression.call("get_talent_tree_names_v72"))
    _check(tree_names == ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"], "tree selector order is stable")

    for tree_value: Variant in tree_names:
        var tree_name: String = str(tree_value)
        var tiers: Array = Array(progression.call("get_talent_tree_tiers_v72", tree_name))
        _check(tiers.size() == 4, "%s exposes four progression tiers" % tree_name)
        var expected_levels: Array[int] = [1, 5, 10, 20]
        var total_nodes: int = 0
        for index: int in range(tiers.size()):
            var tier: Dictionary = Dictionary(tiers[index])
            _check(int(tier.get("level", -1)) == expected_levels[index], "%s tier %d level gate is stable" % [tree_name, index + 1])
            total_nodes += Array(tier.get("talents", [])).size()
        _check(total_nodes == 5, "%s tree contains five existing talents" % tree_name)

    var pathfinder: Dictionary = Dictionary(progression.call("get_talent_definition_v68", "pathfinder"))
    _check(str(pathfinder.get("requires", "")) == "runner", "Pathfinder remains connected to Runner")
    _check(int(pathfinder.get("requires_rank", 0)) == 1, "Pathfinder prerequisite rank retained")
    var ghost: Dictionary = Dictionary(progression.call("get_talent_definition_v68", "ghost_trail"))
    _check(str(ghost.get("requires", "")) == "escape_instinct", "Ghost Trail remains connected to Escape Instinct")

    progression.call("reset_progression_v68", false)
    progression.set("level", 20)
    progression.set("talent_points", 10)
    _check(not bool(progression.call("can_unlock_talent_v72", "pathfinder")), "child node is locked before prerequisite")
    _check(bool(progression.call("can_unlock_talent_v72", "runner")), "root node is available at sufficient level and TP")
    _check(bool(progression.call("unlock_talent_v68", "runner")), "existing unlock API spends root talent")
    _check(bool(progression.call("can_unlock_talent_v72", "pathfinder")), "child node unlocks after prerequisite rank")
    _check(bool(progression.call("unlock_talent_v68", "pathfinder")), "Pathfinder rank 1 unlocks")
    _check(bool(progression.call("unlock_talent_v68", "pathfinder")), "Pathfinder rank 2 unlocks")
    _check(bool(progression.call("can_unlock_talent_v72", "escape_instinct")), "Tier III node unlocks after required rank")

    var save_state: Dictionary = Dictionary(progression.call("get_save_state"))
    _check(int(save_state.get("version", 0)) == 68, "progression save-state remains v68 compatible")
    var saved_talents: Dictionary = Dictionary(save_state.get("talent_ranks", {}))
    _check(int(saved_talents.get("runner", 0)) == 1, "existing talent rank persists in unchanged save format")
    _check(int(saved_talents.get("pathfinder", 0)) == 2, "multi-rank tree node persists in unchanged save format")

    var menu: Node = root.get_node_or_null("ProgressionMenuSystem")
    _check(menu != null, "ProgressionMenuSystem autoload exists")
    if menu != null:
        _check(menu.has_method("get_progression_menu_tree_contract_v72"), "v0.72 tree menu runtime active")
        if menu.has_method("get_progression_menu_tree_contract_v72"):
            var menu_contract: Dictionary = Dictionary(menu.call("get_progression_menu_tree_contract_v72"))
            _check(bool(menu_contract.get("talents_render_as_tree", false)), "menu renders talents as tree")
            _check(bool(menu_contract.get("tree_selector", false)), "menu has specialization selector")
            _check(bool(menu_contract.get("tiered_prerequisite_nodes", false)), "menu exposes prerequisite node tiers")
            _check(bool(menu_contract.get("mobile_vertical", false)), "mobile tree orientation enabled")
            _check(bool(menu_contract.get("desktop_horizontal", false)), "desktop tree orientation enabled")
            _check(bool(menu_contract.get("input_lock_retained", false)), "v0.71 central input lock retained")

    _check(str(ProjectSettings.get_setting("application/config/name", "")).contains("v0.72"), "project version is v0.72")
    progression.call("reset_progression_v68", false)
    _finish_v72()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.72 PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.72 FAIL] %s" % description)

func _finish_v72() -> void:
    if failures.is_empty():
        print("v0.72 talent tree regression: PASS")
        quit(0)
        return
    push_error("v0.72 talent tree regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
