extends "res://scripts/progression_system_v69.gd"

# v0.70 turns the remaining information-oriented talent contracts into concrete,
# read-only gameplay intelligence. It deliberately does not change monster
# damage, world authority, generator resources, or profile/save format.

func get_talent_definition_v68(talent_id: String) -> Dictionary:
    var data: Dictionary = super.get_talent_definition_v68(talent_id)
    match talent_id:
        "escape_instinct":
            data["description"] = "When a learned threat is nearby, show its authored escape/light rule in contextual intel."
        "ghost_trail":
            data["description"] = "Escape intel also exposes your exact player-noise multiplier and carry warning; never grants invisibility."
        "salvager":
            data["description"] = "Unlocks carried salvage/material intelligence; Rank 2 adds electrical-material detail for expedition planning."
        "circuit_memory":
            data["description"] = "In the Mine, show which UPPER/DEEP support-light circuit is active and whether the stabilized junction light is available."
        "emergency_power":
            data["description"] = "Expose low generator fuel/condition warnings and emergency-power readiness; never creates free fuel or permanent power."
        "cold_reader":
            data["description"] = "Reveal advanced analysis for anomaly knowledge you have already discovered; never bypasses evidence collection."
    return data

func get_specialized_knowledge_analysis_v70(knowledge_id: String, player: CharacterBody3D = null) -> String:
    if not has_knowledge_v68(knowledge_id):
        return ""
    var data: Dictionary = get_knowledge_definition_v68(knowledge_id)
    if data.is_empty():
        return ""

    var parts: PackedStringArray = PackedStringArray()
    var category: String = str(data.get("category", ""))
    var advanced: String = str(data.get("advanced", "")).strip_edges()

    if has_talent_v68("escape_instinct"):
        if knowledge_id in ["tenant_presence", "tenant_light_rule"]:
            parts.append("ESCAPE INSTINCT: The Tenant is interrupted by valid world/protected light. A handheld flashlight alone is not a Tenant safe zone.")
        elif knowledge_id in ["darkness_presence", "darkness_light_rule"]:
            parts.append("ESCAPE INSTINCT: Darkness can be pushed back by maintained flashlight light or valid world/protected light; keep the route lit long enough to force withdrawal.")

    if has_talent_v68("ghost_trail") and knowledge_id in ["night_survival", "tenant_presence", "darkness_presence"]:
        parts.append("GHOST TRAIL: Current player-noise output is %.0f%% of baseline. Heavy carry still reduces escape quality." % (get_noise_multiplier_v68() * 100.0))

    if get_talent_rank_v68("salvager") > 0 and knowledge_id == "electrical_salvage":
        parts.append(_salvage_intel_v70(player))

    if has_talent_v68("circuit_memory") and knowledge_id == "mine_circuit":
        parts.append(_mine_circuit_intel_v70())

    if has_talent_v68("emergency_power") and knowledge_id == "generator_maintenance":
        parts.append(_generator_intel_v70())

    if get_talent_rank_v68("threat_familiarity") > 0 and category == "THREAT" and not advanced.is_empty():
        parts.append("THREAT FAMILIARITY: %s" % advanced)

    if has_talent_v68("cold_reader") and category == "ANOMALY" and not advanced.is_empty():
        parts.append("COLD READER: %s" % advanced)

    return "\n".join(parts)

func get_field_intel_cards_v70(player: CharacterBody3D = null) -> Array[Dictionary]:
    var cards: Array[Dictionary] = []

    if has_talent_v68("escape_instinct"):
        cards.append({
            "title": "ESCAPE INSTINCT",
            "text": "Tenant: reach valid world/protected light; flashlight alone is not a safe zone. Darkness: maintain flashlight or world/protected light until it withdraws."
        })

    if has_talent_v68("ghost_trail"):
        var carry_note: String = _carry_intel_v70(player)
        cards.append({
            "title": "GHOST TRAIL",
            "text": "Player-noise output %.0f%% of baseline.%s" % [get_noise_multiplier_v68() * 100.0, carry_note]
        })

    if get_talent_rank_v68("salvager") > 0:
        cards.append({
            "title": "SALVAGER %d/2" % get_talent_rank_v68("salvager"),
            "text": _salvage_intel_v70(player)
        })

    if has_talent_v68("circuit_memory"):
        cards.append({"title": "CIRCUIT MEMORY", "text": _mine_circuit_intel_v70()})

    if has_talent_v68("emergency_power"):
        cards.append({"title": "EMERGENCY POWER", "text": _generator_intel_v70()})

    if has_talent_v68("cold_reader"):
        cards.append({
            "title": "COLD READER",
            "text": "Advanced anomaly analysis is visible only for anomaly entries you have already discovered. Evidence gates and world progression remain unchanged."
        })

    return cards

func get_contextual_intel_v70(player: CharacterBody3D) -> Dictionary:
    if player == null or bool(player.get("is_dead")):
        return {}

    if has_talent_v68("escape_instinct"):
        var darkness: Node3D = get_tree().get_first_node_in_group("darkness_creature") as Node3D
        if darkness != null and is_instance_valid(darkness) and player.global_position.distance_to(darkness.global_position) <= 20.0:
            return {
                "title": "ESCAPE INSTINCT — DARKNESS",
                "text": _append_ghost_trail_v70("Maintain flashlight or valid world/protected light until the manifestation withdraws.", player),
                "priority": 100
            }

        var scene: Node = get_tree().current_scene
        var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D if scene != null else null
        if tenant != null and is_instance_valid(tenant) and player.global_position.distance_to(tenant.global_position) <= 20.0:
            return {
                "title": "ESCAPE INSTINCT — TENANT",
                "text": _append_ghost_trail_v70("Move toward valid world/protected light. Flashlight alone does not create a Tenant safe zone.", player),
                "priority": 100
            }

    if has_talent_v68("emergency_power"):
        var shelter: Node = get_node_or_null("/root/ShelterSystem")
        if shelter != null:
            var fuel_seconds: float = maxf(0.0, float(shelter.get("generator_fuel_seconds")))
            var condition: int = _generator_condition_v70(shelter)
            var broken: bool = bool(shelter.get("generator_broken_v55"))
            if broken or condition <= 30 or (bool(shelter.get("generator_running")) and fuel_seconds <= 60.0):
                return {
                    "title": "EMERGENCY POWER",
                    "text": _generator_intel_v70(),
                    "priority": 80
                }

    var scene_now: Node = get_tree().current_scene
    if has_talent_v68("circuit_memory") and scene_now != null and scene_now.scene_file_path == "res://scenes/mine.tscn":
        return {
            "title": "CIRCUIT MEMORY",
            "text": _mine_circuit_intel_v70(),
            "priority": 60
        }

    return {}

func get_progression_intelligence_contract_v70() -> Dictionary:
    return {
        "profile_format_changed": false,
        "save_schema_changed": false,
        "threat_damage_resistance": false,
        "threat_immunity": false,
        "free_generator_fuel": false,
        "permanent_emergency_power": false,
        "evidence_gate_bypass": false,
        "world_authority_changed": false,
        "contextual_escape_intel": true,
        "live_mine_circuit_intel": true,
        "generator_warning_intel": true,
        "advanced_anomaly_analysis": true,
        "salvage_inventory_intel": true,
        "mobile_desktop_ui_supported": true
    }

func _append_ghost_trail_v70(base_text: String, player: CharacterBody3D) -> String:
    if not has_talent_v68("ghost_trail"):
        return base_text
    return "%s Noise %.0f%%.%s" % [base_text, get_noise_multiplier_v68() * 100.0, _carry_intel_v70(player)]

func _carry_intel_v70(player: CharacterBody3D) -> String:
    if player == null:
        return ""
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_encumbrance_status"):
        return ""
    var status: String = str(carry.call("get_encumbrance_status", player))
    var current: float = float(carry.call("get_current_weight", player)) if carry.has_method("get_current_weight") else 0.0
    var maximum: float = float(carry.call("get_max_weight", player)) if carry.has_method("get_max_weight") else 0.0
    return " Carry %s %.1f/%.1f kg." % [status, current, maximum]

func _salvage_intel_v70(player: CharacterBody3D) -> String:
    if player == null:
        return "Salvage tracking active. Open this panel during an expedition to inspect carried technical materials."
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_item_count"):
        return "Salvage tracking active."
    var scrap: int = int(carry.call("get_item_count", player, "scrap"))
    var electronics: int = int(carry.call("get_item_count", player, "electronics"))
    var rank: int = get_talent_rank_v68("salvager")
    if rank >= 2:
        var copper: int = int(carry.call("get_item_count", player, "copper_wire"))
        var lead: int = int(carry.call("get_item_count", player, "lead_plate"))
        return "Carried salvage — Scrap %d • Electronics %d • Copper Wire %d • Lead Plate %d.%s" % [scrap, electronics, copper, lead, _carry_intel_v70(player)]
    return "Carried salvage — Scrap %d • Electronics %d.%s" % [scrap, electronics, _carry_intel_v70(player)]

func _mine_circuit_intel_v70() -> String:
    var mine: Node = get_node_or_null("/root/MinePowerSystem")
    if mine == null:
        return "Mine routing intel unavailable. Only one UPPER/DEEP support-light circuit can be active at a time."
    var current: String = str(mine.get("current_circuit")).to_upper()
    if current.is_empty():
        current = "UPPER"
    var sample_active: bool = bool(mine.get("sample_bonus_active"))
    return "Active support-light circuit: %s. Stabilized junction light: %s. Switching circuits emits player-originated AI noise." % [current, "ACTIVE" if sample_active else "UNAVAILABLE"]

func _generator_intel_v70() -> String:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return "Generator telemetry unavailable. Emergency Power is information only and never creates free fuel."
    var running: bool = bool(shelter.get("generator_running"))
    var broken: bool = bool(shelter.get("generator_broken_v55"))
    var fuel_seconds: float = maxf(0.0, float(shelter.get("generator_fuel_seconds")))
    var condition: int = _generator_condition_v70(shelter)
    return "Generator %s • condition %d%%%s • fuel reserve ~%ds. Prepare fuel/repair materials before the reserve fails." % [
        "ON" if running else "OFF",
        condition,
        " BROKEN" if broken else "",
        int(ceil(fuel_seconds))
    ]

func _generator_condition_v70(shelter: Node) -> int:
    if shelter != null and shelter.has_method("get_generator_condition_percent_v55"):
        return clampi(int(shelter.call("get_generator_condition_percent_v55")), 0, 100)
    return 100
