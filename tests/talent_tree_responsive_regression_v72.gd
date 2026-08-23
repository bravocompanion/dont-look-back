extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v72")

func _run_v72() -> void:
    await process_frame
    await process_frame

    var menu: Node = root.get_node_or_null("ProgressionMenuSystem")
    _check(menu != null, "ProgressionMenuSystem autoload exists")
    if menu == null:
        _finish_v72()
        return

    _check(menu.has_method("get_talent_tree_layout_mode_v72"), "responsive talent-tree layout API exists")
    if menu.has_method("get_talent_tree_layout_mode_v72"):
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 360.0, false)) == "VERTICAL", "360px uses vertical tree")
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 430.0, false)) == "VERTICAL", "430px uses vertical tree")
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 800.0, false)) == "VERTICAL", "800px uses vertical tree to prevent four-tier clipping")
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 900.0, false)) == "HORIZONTAL", "900px enables horizontal tree")
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 1280.0, false)) == "HORIZONTAL", "1280px uses horizontal tree")
        _check(str(menu.call("get_talent_tree_layout_mode_v72", 1280.0, true)) == "VERTICAL", "mobile platform forces touch-friendly vertical tree")

    var contract: Dictionary = Dictionary(menu.call("get_progression_menu_tree_contract_v72")) if menu.has_method("get_progression_menu_tree_contract_v72") else {}
    _check(float(contract.get("horizontal_breakpoint", 0.0)) == 900.0, "responsive breakpoint is explicit")
    _check(str(contract.get("width_360_mode", "")) == "VERTICAL", "contract records 360px mode")
    _check(str(contract.get("width_430_mode", "")) == "VERTICAL", "contract records 430px mode")
    _check(str(contract.get("width_800_mode", "")) == "VERTICAL", "contract records 800px mode")
    _check(str(contract.get("width_1280_mode", "")) == "HORIZONTAL", "contract records 1280px mode")

    _finish_v72()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.72 RESPONSIVE PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.72 RESPONSIVE FAIL] %s" % description)

func _finish_v72() -> void:
    if failures.is_empty():
        print("v0.72 talent tree responsive regression: PASS")
        quit(0)
        return
    push_error("v0.72 talent tree responsive regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
