extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v70")

func _run_v70() -> void:
    await process_frame
    await process_frame

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    _check(progression != null, "ProgressionSystem autoload exists")
    if progression == null:
        _finish_v70()
        return

    _check(progression.has_method("record_milestone_v69"), "v0.69 milestone API retained")
    _check(progression.has_method("get_progression_intelligence_contract_v70"), "v0.70 intelligence contract exists")
    _check(progression.has_method("get_contextual_intel_v70"), "contextual intel API exists")
    _check(progression.has_method("get_field_intel_cards_v70"), "field intel card API exists")
    _check(progression.has_method("get_specialized_knowledge_analysis_v70"), "specialized knowledge analysis API exists")

    progression.call("reset_progression_v68", false)
    var intelligence: Dictionary = Dictionary(progression.call("get_progression_intelligence_contract_v70"))
    _check(not bool(intelligence.get("profile_format_changed", true)), "profile format unchanged")
    _check(not bool(intelligence.get("save_schema_changed", true)), "save schema unchanged")
    _check(not bool(intelligence.get("threat_damage_resistance", true)), "no threat damage resistance")
    _check(not bool(intelligence.get("threat_immunity", true)), "no threat immunity")
    _check(not bool(intelligence.get("free_generator_fuel", true)), "Emergency Power grants no free fuel")
    _check(not bool(intelligence.get("permanent_emergency_power", true)), "Emergency Power is not permanent free power")
    _check(not bool(intelligence.get("evidence_gate_bypass", true)), "Cold Reader does not bypass evidence gates")
    _check(not bool(intelligence.get("world_authority_changed", true)), "world authority unchanged")

    var save_state: Dictionary = Dictionary(progression.call("get_save_state"))
    _check(int(save_state.get("version", 0)) == 68, "progression save-state version remains 68")
    var profile_contract: Dictionary = Dictionary(progression.call("get_profile_contract_v68"))
    _check(str(profile_contract.get("path", "")).contains("progression_v68"), "local profile path remains v68-compatible")

    var changed_descriptions: Array[String] = [
        "escape_instinct", "ghost_trail", "salvager", "circuit_memory", "emergency_power", "cold_reader"
    ]
    for talent_id: String in changed_descriptions:
        var data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", talent_id))
        _check(not str(data.get("description", "")).is_empty(), "%s has concrete v0.70 description" % talent_id)
    var salvager_data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", "salvager"))
    _check(not str(salvager_data.get("description", "")).contains("future material bonus hooks"), "Salvager no longer advertises an unimplemented future hook")

    var talents: Dictionary = Dictionary(progression.get("talent_ranks"))
    talents["escape_instinct"] = 1
    talents["ghost_trail"] = 1
    talents["salvager"] = 2
    talents["circuit_memory"] = 1
    talents["emergency_power"] = 1
    talents["threat_familiarity"] = 1
    talents["cold_reader"] = 1
    progression.set("talent_ranks", talents)

    progression.call("unlock_knowledge_v68", "tenant_presence", false)
    progression.call("unlock_knowledge_v68", "darkness_presence", false)
    progression.call("unlock_knowledge_v68", "electrical_salvage", false)
    progression.call("unlock_knowledge_v68", "mine_circuit", false)
    progression.call("unlock_knowledge_v68", "generator_maintenance", false)
    progression.call("unlock_knowledge_v68", "water_anomaly", false)

    var tenant_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "tenant_presence", null))
    _check(tenant_analysis.contains("ESCAPE INSTINCT"), "Escape Instinct adds learned Tenant guidance")
    _check(tenant_analysis.contains("flashlight"), "Tenant intel explicitly preserves flashlight limitation")

    var darkness_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "darkness_presence", null))
    _check(darkness_analysis.contains("ESCAPE INSTINCT"), "Escape Instinct adds learned Darkness guidance")

    var salvage_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "electrical_salvage", null))
    _check(salvage_analysis.contains("Salvage tracking active"), "Salvager provides read-only inventory planning intel")

    var circuit_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "mine_circuit", null))
    _check(circuit_analysis.contains("Active support-light circuit"), "Circuit Memory exposes live Mine circuit state")
    _check(circuit_analysis.contains("AI noise"), "Circuit Memory warns that switching circuits still creates AI noise")

    var generator_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "generator_maintenance", null))
    _check(generator_analysis.contains("condition"), "Emergency Power exposes generator condition telemetry")
    _check(generator_analysis.contains("fuel reserve"), "Emergency Power exposes generator fuel telemetry")

    var anomaly_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "water_anomaly", null))
    _check(anomaly_analysis.contains("COLD READER"), "Cold Reader exposes advanced analysis for discovered anomaly knowledge")

    var undiscovered_analysis: String = str(progression.call("get_specialized_knowledge_analysis_v70", "containment_topology", null))
    _check(undiscovered_analysis.is_empty(), "Cold Reader cannot reveal undiscovered evidence-gated knowledge")

    var cards_value: Variant = progression.call("get_field_intel_cards_v70", null)
    _check(cards_value is Array, "field intel cards return an Array")
    if cards_value is Array:
        var cards: Array = Array(cards_value)
        _check(cards.size() >= 6, "all six information-specialization talents surface active intel")

    var intel_hud: Node = root.get_node_or_null("ProgressionIntelHUD")
    _check(intel_hud != null, "ProgressionIntelHUD autoload exists")
    if intel_hud != null and intel_hud.has_method("get_intel_hud_contract_v70"):
        var hud_contract: Dictionary = Dictionary(intel_hud.call("get_intel_hud_contract_v70"))
        _check(bool(hud_contract.get("contextual_only", false)), "intel HUD remains contextual instead of permanent")
        _check(bool(hud_contract.get("mobile_responsive", false)), "intel HUD is mobile responsive")
        _check(bool(hud_contract.get("desktop_responsive", false)), "intel HUD is desktop responsive")
        _check(not bool(hud_contract.get("new_art_required", true)), "intel HUD requires no new art")
        _check(not bool(hud_contract.get("changes_world_authority", true)), "intel HUD is read-only")
    else:
        _check(false, "ProgressionIntelHUD exposes v0.70 contract")

    var menu: Node = root.get_node_or_null("ProgressionMenuSystem")
    _check(menu != null and menu.has_method("get_progression_menu_intel_contract_v70"), "Progression menu v0.70 runtime active")
    if menu != null and menu.has_method("get_progression_menu_intel_contract_v70"):
        var menu_contract: Dictionary = Dictionary(menu.call("get_progression_menu_intel_contract_v70"))
        _check(bool(menu_contract.get("active_specialization_cards", false)), "menu shows active specialization cards")
        _check(bool(menu_contract.get("knowledge_talent_analysis", false)), "menu shows talent analysis for known knowledge")
        _check(bool(menu_contract.get("mobile_responsive", false)), "progression intel menu remains mobile responsive")
        _check(bool(menu_contract.get("input_lock_retained", false)), "progression menu input lock retained")

    _check(str(ProjectSettings.get_setting("application/config/name", "")).contains("v0.70"), "project version is v0.70")
    _finish_v70()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.70 PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.70 FAIL] %s" % description)

func _finish_v70() -> void:
    if failures.is_empty():
        print("v0.70 progression intelligence regression: PASS")
        quit(0)
        return
    push_error("v0.70 progression intelligence regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
