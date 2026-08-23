extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v71")

func _run_v71() -> void:
    await process_frame
    await process_frame
    await process_frame

    var coordinator: Node = root.get_node_or_null("UIRuntimeCoordinator")
    _check(coordinator != null, "UIRuntimeCoordinator autoload exists")
    if coordinator != null:
        _check(bool(Dictionary(coordinator.call("get_layout_contract_v71")).get("single_source_of_truth", false)), "HUD lanes use a single geometry source")
        _check_layout_v71(coordinator, Vector2(1280, 720), false, "1280x720 desktop")
        _check_layout_v71(coordinator, Vector2(800, 600), false, "800x600 desktop")
        _check_layout_v71(coordinator, Vector2(430, 800), true, "430x800 mobile")
        _check_layout_v71(coordinator, Vector2(360, 640), true, "360x640 mobile")

    var lock: Node = root.get_node_or_null("GameplayInputLock")
    _check(lock != null and lock.has_method("get_ui_lock_contract_v71"), "GameplayInputLock v0.71 active")
    if lock != null and lock.has_method("get_ui_lock_contract_v71"):
        var lock_contract: Dictionary = Dictionary(lock.call("get_ui_lock_contract_v71"))
        for key: String in ["inventory_covered", "progression_covered", "front_end_covered", "crafting_covered", "stash_covered", "journal_covered", "field_status_covered"]:
            _check(bool(lock_contract.get(key, false)), "central lock covers %s" % key)
        lock.call("acquire", "V71_REGRESSION")
        _check(bool(lock.call("is_reason_locked", "V71_REGRESSION")), "manual same-frame UI lock works")
        lock.call("release", "V71_REGRESSION")

    var survival: Node = root.get_node_or_null("SurvivalSystem")
    _check(survival != null and survival.has_method("get_survival_ui_collision_contract_v71"), "SurvivalSystem v0.71 active")
    if survival != null:
        var survival_contract: Dictionary = Dictionary(survival.call("get_survival_ui_collision_contract_v71"))
        _check(str(survival_contract.get("inventory_menu", "")).ends_with("inventory_menu_system_v58.gd"), "collision-safe inventory runtime is wired")
        _check(bool(survival_contract.get("weight_system_retained", false)), "weight system retained")
        _check(bool(survival_contract.get("progression_milestones_retained", false)), "progression milestones retained")

    var inventory: Node = root.get_node_or_null("SurvivalSystem/InventoryMenuRuntime")
    _check(inventory != null and inventory.has_method("get_inventory_collision_contract_v71"), "Inventory v58 runtime active")
    if inventory != null and inventory.has_method("get_inventory_collision_contract_v71"):
        var inv: Dictionary = Dictionary(inventory.call("get_inventory_collision_contract_v71"))
        _check(str(inv.get("movement_authority", "")) == "GameplayInputLock", "inventory uses central movement authority")
        _check(not bool(inv.get("direct_player_physics_ownership", true)), "inventory no longer owns Player physics processing")
        _check(not bool(inv.get("direct_player_process_ownership", true)), "inventory no longer owns Player process state")
        _check(not bool(inv.get("direct_mobile_external_block_ownership", true)), "inventory no longer owns MobileControls shared boolean")
        _check(bool(inv.get("manual_same_frame_lock", false)), "inventory locks in the same frame it opens")

    var progression_menu: Node = root.get_node_or_null("ProgressionMenuSystem")
    _check(progression_menu != null and progression_menu.has_method("get_progression_menu_collision_contract_v71"), "Progression menu v0.71 active")
    if progression_menu != null and progression_menu.has_method("get_progression_menu_collision_contract_v71"):
        var menu_contract: Dictionary = Dictionary(progression_menu.call("get_progression_menu_collision_contract_v71"))
        _check(not bool(menu_contract.get("direct_mobile_external_block_ownership", true)), "progression menu no longer races MobileControls shared boolean")
        _check(bool(menu_contract.get("coordinated_prog_button_layout", false)), "PROG button uses shared safe layout")

    var feedback: Node = root.get_node_or_null("ProgressionFeedbackHUD")
    _check(feedback != null and feedback.has_method("get_feedback_hud_collision_contract_v71"), "Progression feedback HUD v0.71 active")
    if feedback != null and feedback.has_method("get_feedback_hud_collision_contract_v71"):
        var feedback_contract: Dictionary = Dictionary(feedback.call("get_feedback_hud_collision_contract_v71"))
        _check(bool(feedback_contract.get("toast_replaces_strip", false)), "toast replaces XP strip instead of stacking")
        _check(bool(feedback_contract.get("hides_during_modal_ui", false)), "progression feedback hides during modal UI")

    var intel: Node = root.get_node_or_null("ProgressionIntelHUD")
    _check(intel != null and intel.has_method("get_intel_hud_collision_contract_v71"), "Progression intel HUD v0.71 active")
    if intel != null and intel.has_method("get_intel_hud_collision_contract_v71"):
        var intel_contract: Dictionary = Dictionary(intel.call("get_intel_hud_collision_contract_v71"))
        _check(int(intel_contract.get("mobile_max_lines", 99)) == 3, "mobile intel is line-clamped")
        _check(not bool(intel_contract.get("changes_world_authority", true)), "intel HUD remains read-only")

    var hud: Node = root.get_node_or_null("HUDLayoutSystem")
    _check(hud != null and hud.has_method("get_hud_collision_contract_v71"), "HUDLayoutSystem v0.71 active")

    var front: Node = root.get_node_or_null("FrontEndSystem")
    _check(front != null and front.has_method("get_front_end_collision_contract_v71"), "FrontEnd v0.71 collision layout active")
    if front != null and front.has_method("get_front_end_collision_contract_v71"):
        var front_contract: Dictionary = Dictionary(front.call("get_front_end_collision_contract_v71"))
        _check(bool(front_contract.get("mobile_menu_uses_coordinator", false)), "mobile MENU uses safe button row")
        _check(bool(front_contract.get("session_prestart_mobile_block_retained", false)), "pre-start multiplayer touch block retained")

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    _check(progression != null, "ProgressionSystem retained")
    if progression != null:
        var save_state: Dictionary = Dictionary(progression.call("get_save_state"))
        _check(int(save_state.get("version", -1)) == 68, "progression save schema remains version 68")
        var profile_contract: Dictionary = Dictionary(progression.call("get_profile_contract_v68"))
        _check(str(profile_contract.get("path", "")).contains("progression_v68"), "local progression profile remains compatible")

    _check(str(ProjectSettings.get_setting("application/config/name", "")).begins_with("Don't Look Back v0."), "v0.71 behavior regression remains valid in later releases")
    _finish_v71()

func _check_layout_v71(coordinator: Node, size: Vector2, compact: bool, label: String) -> void:
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", size, compact))
    var progression: Rect2 = layout.get("progression", Rect2())
    var toast: Rect2 = layout.get("toast", Rect2())
    _check(progression == toast, "%s toast shares progression lane" % label)
    _no_overlap(layout, "status", "progression", label)
    _no_overlap(layout, "progression", "objective", label)
    _no_overlap(layout, "objective", "intel", label)
    _no_overlap(layout, "progression", "intel", label)

    if compact:
        _no_overlap(layout, "progression", "bag_button", label)
        _no_overlap(layout, "progression", "menu_button", label)
        _no_overlap(layout, "progression", "prog_button", label)
        _no_overlap(layout, "bag_button", "menu_button", label)
        _no_overlap(layout, "menu_button", "prog_button", label)
        _no_overlap(layout, "bag_button", "objective", label)
        _no_overlap(layout, "menu_button", "objective", label)
        _no_overlap(layout, "prog_button", "objective", label)
        _no_overlap(layout, "bag_button", "intel", label)
        _no_overlap(layout, "menu_button", "intel", label)
        _no_overlap(layout, "prog_button", "intel", label)

    for key: String in ["status", "progression", "objective", "intel"]:
        var rect: Rect2 = layout.get(key, Rect2())
        _check(rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= size.x + 0.01 and rect.end.y <= size.y + 0.01, "%s %s stays inside viewport" % [label, key])

func _no_overlap(layout: Dictionary, a_key: String, b_key: String, label: String) -> void:
    var a: Rect2 = layout.get(a_key, Rect2())
    var b: Rect2 = layout.get(b_key, Rect2())
    _check(not a.intersects(b, true), "%s %s does not collide with %s" % [label, a_key, b_key])

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.71 PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.71 FAIL] %s" % description)

func _finish_v71() -> void:
    if failures.is_empty():
        print("v0.71 UI/code collision regression: PASS")
        quit(0)
        return
    push_error("v0.71 UI/code collision regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
