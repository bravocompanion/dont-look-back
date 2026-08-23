extends SceneTree

var failures: Array[String] = []

func _init() -> void:
    call_deferred("_run_v73")

func _run_v73() -> void:
    await process_frame
    await process_frame
    await process_frame

    var registry: Node = root.get_node_or_null("TalentIconRegistry")
    _check(registry != null, "TalentIconRegistry autoload exists")
    if registry != null:
        _check(registry.has_method("get_talent_icon_contract_v73"), "talent icon registry contract exists")
        var icon_contract: Dictionary = Dictionary(registry.call("get_talent_icon_contract_v73"))
        _check(bool(icon_contract.get("generated_icon_atlas_integrated", false)), "generated talent icon atlas decodes successfully")
        _check(int(icon_contract.get("icon_count", 0)) == 20, "all 20 generated talent icons are mapped")
        _check(Vector2i(icon_contract.get("atlas_size", Vector2i.ZERO)) == Vector2i(320, 256), "runtime talent atlas is 320x256")
        _check(Vector2i(icon_contract.get("cell_size", Vector2i.ZERO)) == Vector2i(64, 64), "talent icon cells are 64x64")
        _check(not bool(icon_contract.get("requires_external_png", true)), "runtime atlas is self-contained in repository text assets")

        var icon_ids: Array = Array(registry.call("get_talent_icon_ids_v73"))
        _check(icon_ids.size() == 20, "icon registry exposes 20 talent IDs")
        var unique_regions: Dictionary = {}
        for talent_value: Variant in icon_ids:
            var talent_id: String = str(talent_value)
            var texture: Texture2D = registry.call("get_talent_icon_v73", talent_id) as Texture2D
            _check(texture != null, "%s has a runtime icon" % talent_id)
            if texture is AtlasTexture:
                var atlas_icon: AtlasTexture = texture as AtlasTexture
                unique_regions[str(atlas_icon.region)] = true
        _check(unique_regions.size() == 20, "all 20 talents use unique atlas regions")

    var progression: Node = root.get_node_or_null("ProgressionSystem")
    _check(progression != null, "ProgressionSystem autoload exists")
    if progression != null:
        _check(progression.has_method("get_talent_tree_edges_v73"), "real graph edge API exists")
        _check(progression.has_method("get_talent_visual_node_v73"), "visual node API exists")
        _check(progression.has_method("get_talent_visual_tree_contract_v73"), "v0.73 visual tree contract exists")
        var visual_contract: Dictionary = Dictionary(progression.call("get_talent_visual_tree_contract_v73"))
        _check(bool(visual_contract.get("graphical_parent_child_edges", false)), "parent-child graph edges enabled")
        _check(bool(visual_contract.get("edges_derived_from_existing_requires", false)), "graph edges come from existing prerequisite data")
        _check(not bool(visual_contract.get("fake_prerequisites_added", true)), "no fake prerequisite edges are introduced")
        _check(int(visual_contract.get("unique_generated_icon_nodes", 0)) == 20, "visual contract requires 20 unique icon nodes")
        _check(not bool(visual_contract.get("save_schema_changed", true)), "progression save schema unchanged")
        _check(not bool(visual_contract.get("profile_format_changed", true)), "progression profile format unchanged")
        _check(not bool(visual_contract.get("talent_balance_changed", true)), "talent effects and balance unchanged")
        _check(not bool(visual_contract.get("network_authority_changed", true)), "multiplayer/network authority unchanged")

        var expected_edges: Dictionary = {
            "SURVIVAL": ["efficient_metabolism>pack_discipline", "pack_discipline>load_bearing", "load_bearing>last_reserve"],
            "SCOUT": ["runner>pathfinder", "pathfinder>escape_instinct", "escape_instinct>ghost_trail"],
            "TECHNICIAN": ["quick_repair>fuel_economy", "fuel_economy>circuit_memory", "circuit_memory>emergency_power"],
            "INVESTIGATOR": ["evidence_analyst>pattern_recognition", "pattern_recognition>threat_familiarity", "threat_familiarity>cold_reader"]
        }
        for tree_name: String in ["SURVIVAL", "SCOUT", "TECHNICIAN", "INVESTIGATOR"]:
            var edges: Array = Array(progression.call("get_talent_tree_edges_v73", tree_name))
            _check(edges.size() == 3, "%s has exactly three authored parent-child edges" % tree_name)
            var actual: Dictionary = {}
            for edge_value: Variant in edges:
                var edge: Dictionary = Dictionary(edge_value)
                var key: String = "%s>%s" % [str(edge.get("parent_id", "")), str(edge.get("child_id", ""))]
                actual[key] = true
                var child_data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", str(edge.get("child_id", ""))))
                _check(str(child_data.get("requires", "")) == str(edge.get("parent_id", "")), "%s edge matches child requires field" % key)
            for expected_value: Variant in Array(expected_edges[tree_name]):
                _check(actual.has(str(expected_value)), "%s authored edge %s is present" % [tree_name, str(expected_value)])

        var independent_roots: Array[String] = ["field_medic", "quiet_steps", "salvager", "steady_hands"]
        for root_id: String in independent_roots:
            var root_data: Dictionary = Dictionary(progression.call("get_talent_definition_v68", root_id))
            _check(str(root_data.get("requires", "")).is_empty(), "%s remains an independent branch node" % root_id)

        var save_state: Dictionary = Dictionary(progression.call("get_save_state"))
        _check(int(save_state.get("version", -1)) == 68, "progression save-state version remains 68")
        var profile_contract: Dictionary = Dictionary(progression.call("get_profile_contract_v68"))
        _check(str(profile_contract.get("path", "")).contains("progression_v68"), "existing local progression profile path retained")

    var menu: Node = root.get_node_or_null("ProgressionMenuSystem")
    _check(menu != null and menu.has_method("get_progression_menu_visual_tree_contract_v73"), "v0.73 visual progression menu runtime active")
    if menu != null and menu.has_method("get_progression_menu_visual_tree_contract_v73"):
        var menu_contract: Dictionary = Dictionary(menu.call("get_progression_menu_visual_tree_contract_v73"))
        _check(bool(menu_contract.get("true_parent_child_lines", false)), "menu uses true graphical parent-child lines")
        _check(bool(menu_contract.get("unique_icon_per_talent_node", false)), "menu uses unique icons on talent nodes")
        _check(bool(menu_contract.get("node_click_selects_only", false)), "node click only selects and does not spend points")
        _check(bool(menu_contract.get("explicit_unlock_button", false)), "Talent Point spending remains explicit")
        _check(bool(menu_contract.get("long_description_moved_to_detail_panel", false)), "long descriptions moved out of graph nodes")
        _check(bool(menu_contract.get("flat_text_card_tree_replaced", false)), "text-heavy card tree is replaced")
        _check(bool(menu_contract.get("v071_input_lock_retained", false)), "central GameplayInputLock retained")
        _check(bool(menu_contract.get("v072_responsive_breakpoint_retained", false)), "v0.72 mobile/desktop breakpoint retained")

    var graph_script: Script = load("res://scripts/talent_tree_graph_v73.gd") as Script
    _check(graph_script != null, "graphical tree Control script loads")
    if graph_script != null:
        var graph: Control = graph_script.new() as Control
        _check(graph != null and graph.has_method("get_graph_contract_v73"), "graph Control exposes visual contract")
        if graph != null:
            var graph_contract: Dictionary = Dictionary(graph.call("get_graph_contract_v73"))
            _check(bool(graph_contract.get("graphical_connectors", false)), "graph draws connectors")
            _check(str(graph_contract.get("connector_renderer", "")) == "native_draw_polyline", "connectors use native Godot drawing")
            _check(bool(graph_contract.get("arrowheads", false)), "connector arrowheads point toward children")
            _check(bool(graph_contract.get("lines_render_behind_nodes", false)), "connectors render behind node UI")
            _check(not bool(graph_contract.get("long_description_inside_node", true)), "graph nodes stay compact")
            graph.free()

    var front: Node = root.get_node_or_null("FrontEndSystem")
    _check(front != null and front.has_method("get_front_end_visual_talent_tree_contract_v73"), "front-end v0.73 runtime active")
    _check(str(ProjectSettings.get_setting("application/config/name", "")).contains("v0.73"), "project version is v0.73")
    _finish_v73()

func _check(condition: bool, description: String) -> void:
    if condition:
        print("[v0.73 PASS] %s" % description)
    else:
        failures.append(description)
        push_error("[v0.73 FAIL] %s" % description)

func _finish_v73() -> void:
    if failures.is_empty():
        print("v0.73 visual talent tree regression: PASS")
        quit(0)
        return
    push_error("v0.73 visual talent tree regression: %d failure(s)" % failures.size())
    for failure: String in failures:
        push_error(" - %s" % failure)
    quit(1)
