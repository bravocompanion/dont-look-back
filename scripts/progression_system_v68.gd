extends Node

signal progression_changed
signal level_up(new_level: int)
signal knowledge_unlocked(knowledge_id: String)
signal progression_feedback(message: String)

const MAX_LEVEL: int = 30
const MAX_STAT_VALUE: int = 15
const BASE_STAT_VALUE: int = 0

const STAT_IDS: Array[String] = ["endurance", "fitness", "fortitude", "focus", "dexterity"]
const STAT_NAMES: Dictionary = {
    "endurance": "Endurance",
    "fitness": "Fitness",
    "fortitude": "Fortitude",
    "focus": "Focus",
    "dexterity": "Dexterity"
}
const STAT_DESCRIPTIONS: Dictionary = {
    "endurance": "+1 max stamina and +0.10 kg carry tolerance per point.",
    "fitness": "+0.2% movement speed per point.",
    "fortitude": "-0.5% hunger/thirst drain per point.",
    "focus": "-1% effective flashlight panic per point.",
    "dexterity": "-0.5% vulnerable supply-use time per point."
}

const TALENT_ORDER: Array[String] = [
    "efficient_metabolism", "field_medic", "pack_discipline", "load_bearing", "last_reserve",
    "runner", "quiet_steps", "pathfinder", "escape_instinct", "ghost_trail",
    "quick_repair", "fuel_economy", "salvager", "circuit_memory", "emergency_power",
    "steady_hands", "evidence_analyst", "pattern_recognition", "threat_familiarity", "cold_reader"
]

const TALENTS: Dictionary = {
    "efficient_metabolism": {"tree": "SURVIVAL", "name": "Efficient Metabolism", "max_rank": 3, "min_level": 1, "description": "Hunger/thirst drain -3% per rank."},
    "field_medic": {"tree": "SURVIVAL", "name": "Field Medic", "max_rank": 2, "min_level": 1, "description": "Medkit and supply-use time -8% per rank."},
    "pack_discipline": {"tree": "SURVIVAL", "name": "Pack Discipline", "max_rank": 1, "min_level": 5, "requires": "efficient_metabolism", "requires_rank": 1, "description": "LOADED starts at 75% carry instead of 70%."},
    "load_bearing": {"tree": "SURVIVAL", "name": "Load Bearing", "max_rank": 2, "min_level": 10, "requires": "pack_discipline", "requires_rank": 1, "description": "+1.0 kg maximum carry per rank."},
    "last_reserve": {"tree": "SURVIVAL", "name": "Last Reserve", "max_rank": 1, "min_level": 20, "requires": "load_bearing", "requires_rank": 2, "description": "When exhausted, retain a small stamina recovery reserve; never grants unlimited sprint."},

    "runner": {"tree": "SCOUT", "name": "Runner", "max_rank": 3, "min_level": 1, "description": "Sprint stamina drain -4% per rank."},
    "quiet_steps": {"tree": "SCOUT", "name": "Quiet Steps", "max_rank": 3, "min_level": 1, "description": "Player-generated AI noise -4% per rank."},
    "pathfinder": {"tree": "SCOUT", "name": "Pathfinder", "max_rank": 2, "min_level": 5, "requires": "runner", "requires_rank": 1, "description": "Movement speed +0.5% per rank."},
    "escape_instinct": {"tree": "SCOUT", "name": "Escape Instinct", "max_rank": 1, "min_level": 10, "requires": "pathfinder", "requires_rank": 2, "description": "Threat journal exposes pursuit/escape guidance after observation."},
    "ghost_trail": {"tree": "SCOUT", "name": "Ghost Trail", "max_rank": 1, "min_level": 20, "requires": "escape_instinct", "requires_rank": 1, "description": "After surviving major pursuit, movement noise guidance becomes more precise; no invisibility."},

    "quick_repair": {"tree": "TECHNICIAN", "name": "Quick Repair", "max_rank": 3, "min_level": 1, "description": "Technical interaction modifier -6% time per rank."},
    "fuel_economy": {"tree": "TECHNICIAN", "name": "Fuel Economy", "max_rank": 2, "min_level": 5, "requires": "quick_repair", "requires_rank": 1, "description": "Generator fuel effectiveness +6% per rank."},
    "salvager": {"tree": "TECHNICIAN", "name": "Salvager", "max_rank": 2, "min_level": 5, "description": "Unlocks better salvage knowledge and future material bonus hooks."},
    "circuit_memory": {"tree": "TECHNICIAN", "name": "Circuit Memory", "max_rank": 1, "min_level": 10, "requires": "fuel_economy", "requires_rank": 1, "description": "Electrical/circuit knowledge reveals exact learned sequence notes."},
    "emergency_power": {"tree": "TECHNICIAN", "name": "Emergency Power", "max_rank": 1, "min_level": 20, "requires": "circuit_memory", "requires_rank": 1, "description": "Unlocks the emergency-power knowledge contract; does not create free permanent power."},

    "steady_hands": {"tree": "INVESTIGATOR", "name": "Steady Hands", "max_rank": 3, "min_level": 1, "description": "Effective flashlight panic -5% per rank."},
    "evidence_analyst": {"tree": "INVESTIGATOR", "name": "Evidence Analyst", "max_rank": 2, "min_level": 1, "description": "Evidence XP +10% per rank."},
    "pattern_recognition": {"tree": "INVESTIGATOR", "name": "Pattern Recognition", "max_rank": 2, "min_level": 5, "requires": "evidence_analyst", "requires_rank": 1, "description": "Observed threat knowledge gains increasingly explicit behavioral hints."},
    "threat_familiarity": {"tree": "INVESTIGATOR", "name": "Threat Familiarity", "max_rank": 2, "min_level": 10, "requires": "pattern_recognition", "requires_rank": 2, "description": "Threat journal exposes known protection rules without damage resistance."},
    "cold_reader": {"tree": "INVESTIGATOR", "name": "Cold Reader", "max_rank": 1, "min_level": 20, "requires": "threat_familiarity", "requires_rank": 2, "description": "High-tier anomaly notes become readable after observation; no monster immunity."}
}

const KNOWLEDGE_ORDER: Array[String] = [
    "ranger_yard", "night_survival", "generator_maintenance", "field_medicine", "water_safety",
    "electrical_salvage", "wildlife_anatomy", "mine_route", "mine_circuit", "labyrinth_rules",
    "research_anomaly", "tenant_presence", "tenant_light_rule", "darkness_presence", "darkness_light_rule",
    "survey_team", "radio_trace", "water_anomaly", "facility_access", "containment_topology"
]

const KNOWLEDGE: Dictionary = {
    "ranger_yard": {"category": "SURVIVAL", "title": "Ranger Yard", "body": "A powered generator or established campfire can turn the Ranger Yard into a reliable recovery point.", "advanced": "Stable world light is more important than raw brightness when judging authored protection zones."},
    "night_survival": {"category": "SURVIVAL", "title": "Surviving the Night", "body": "Night is a resource problem: light, shelter, stamina and a route home matter more than fighting.", "advanced": "Plan the return before dusk; exhaustion and heavy carry compound escape risk."},
    "generator_maintenance": {"category": "TECHNOLOGY", "title": "Generator Maintenance", "body": "Fuel alone is not enough forever. Condition, repair materials and timing decide whether shelter power survives the night.", "advanced": "Repair preparation is cheaper than gambling on a critical generator during a major threat."},
    "field_medicine": {"category": "SURVIVAL", "title": "Field Medicine", "body": "Treatment is vulnerable. Stabilize position and create distance before committing to a medkit.", "advanced": "Field Medic reduces exposure time, not incoming damage."},
    "water_safety": {"category": "SURVIVAL", "title": "Water Safety", "body": "Dirty water is a resource only after processing. Boiling requires an active campfire and the correct work area.", "advanced": "Carry weight makes water planning as important as availability."},
    "electrical_salvage": {"category": "TECHNOLOGY", "title": "Electrical Salvage", "body": "Scrap and electronics support batteries, generator repair and later infrastructure.", "advanced": "Technician talents improve efficiency but never make electrical resources free."},
    "wildlife_anatomy": {"category": "WILDLIFE", "title": "Wildlife Anatomy", "body": "Wildlife can feed an expedition, but wounded animals flee and repeated hits do not magically stack movement speed.", "advanced": "A clean recovery route matters because hunting can pull you away from shelter before dark."},
    "mine_route": {"category": "WORLD", "title": "Old Mine Route", "body": "The survey trail converges on the old mine and its maintenance infrastructure.", "advanced": "Mine access is progression, not a combat gate. Evidence and power routing matter more than kills."},
    "mine_circuit": {"category": "TECHNOLOGY", "title": "Mine Power Routing", "body": "Upper and Deep power are mutually constrained. Treat switching as an information and noise decision.", "advanced": "Circuit Memory preserves learned sequence guidance and helps avoid repeat mistakes."},
    "labyrinth_rules": {"category": "ANOMALY", "title": "Labyrinth Rules", "body": "The Labyrinth changes rules by stage: darkness, false noise, stabilizers, breaker order and moving lockdown space.", "advanced": "No single build bypasses stage rules; coordination remains mandatory."},
    "research_anomaly": {"category": "ANOMALY", "title": "Research Facility", "body": "The facility converts evidence into a campaign choice: rescue priority or anomaly priority.", "advanced": "Knowledge changes what you understand, not how much damage monsters take."},
    "tenant_presence": {"category": "THREAT", "title": "The Tenant — Presence", "body": "A humanoid presence stalks survivors. Observation and stable world protection change how safely you can occupy space.", "advanced": "Do not assume a handheld flashlight is equivalent to an authored safe-zone light."},
    "tenant_light_rule": {"category": "THREAT", "title": "The Tenant — Light Rule", "body": "World/protected light can interrupt the Tenant's pressure. Personal flashlight light is not the same safe-zone contract.", "advanced": "Threat Familiarity reveals this rule because it was learned, not because the character gained resistance."},
    "darkness_presence": {"category": "THREAT", "title": "Darkness — Manifestation", "body": "The Darkness is tied to losing protection and can become an immediate pursuit threat.", "advanced": "Its identity is exposure to unprotected darkness, not simply a dark-colored enemy."},
    "darkness_light_rule": {"category": "THREAT", "title": "Darkness — Light Rule", "body": "Flashlight or valid world protection can force Darkness withdrawal when maintained long enough.", "advanced": "Light must remain available; battery, panic and route planning still matter."},
    "survey_team": {"category": "WORLD", "title": "Survey Manifest", "body": "The missing survey team left a physical route through the Forest toward industrial access.", "advanced": "Cross-checking evidence matters more than collecting isolated notes."},
    "radio_trace": {"category": "WORLD", "title": "Broken Radio Trace", "body": "The communications trail carries a maintenance frequency linked to the survey route.", "advanced": "Pair it with the manifest at the Ranger Case Board."},
    "water_anomaly": {"category": "ANOMALY", "title": "Anomalous Water Sample", "body": "The water sample is more than contamination; it can stabilize later mine-lighting analysis.", "advanced": "Optional evidence can produce practical route advantages without becoming raw combat power."},
    "facility_access": {"category": "WORLD", "title": "Facility Access Trail", "body": "Mine evidence points beyond industrial infrastructure toward a sealed research installation.", "advanced": "Access knowledge persists even when a checkpoint rolls shared world state backward."},
    "containment_topology": {"category": "ANOMALY", "title": "Containment Topology", "body": "Research data describes the anomaly as a spatial/behavioral system rather than a conventional creature.", "advanced": "The campaign route can prioritize containment intelligence instead of rescue response."}
}

const SCENE_XP: Dictionary = {
    "res://scenes/forest.tscn": 20,
    "res://scenes/mine.tscn": 120,
    "res://scenes/main.tscn": 180,
    "res://scenes/research_facility.tscn": 220
}

const SCENE_KNOWLEDGE: Dictionary = {
    "res://scenes/forest.tscn": "ranger_yard",
    "res://scenes/mine.tscn": "mine_route",
    "res://scenes/main.tscn": "labyrinth_rules",
    "res://scenes/research_facility.tscn": "research_anomaly"
}

const EVIDENCE_KNOWLEDGE: Dictionary = {
    "survey_manifest": "survey_team",
    "radio_trace": "radio_trace",
    "maintenance_map": "mine_route",
    "water_sample": "water_anomaly",
    "foreman_log": "mine_circuit",
    "sealed_shaft_report": "mine_route",
    "facility_badge": "facility_access",
    "facility_terminal": "containment_topology"
}

var level: int = 1
var xp_in_level: int = 0
var talent_points: int = 0
var stat_points: int = 0
var stats: Dictionary = {}
var talent_ranks: Dictionary = {}
var knowledge_unlocked_ids: Dictionary = {}
var claimed_xp_events: Dictionary = {}
var last_scene_path: String = ""
var active_night_start_day: int = -1
var previous_generator_running: bool = false
var poll_timer: float = 0.0
var restoring_state: bool = false
var last_player_id: int = 0
var player_baselines: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 120
    reset_progression_v68(false)

func _process(delta: float) -> void:
    poll_timer -= delta
    if poll_timer > 0.0:
        return
    poll_timer = 0.20

    var player: CharacterBody3D = _local_player()
    if player != null:
        _apply_runtime_modifiers_v68(player)
        _monitor_scene_discovery_v68()
        _monitor_threat_knowledge_v68(player)
        _monitor_night_survival_v68(player)
        _monitor_generator_v68()

func xp_to_next_level_v68(for_level: int = -1) -> int:
    var target_level: int = level if for_level < 0 else clampi(for_level, 1, MAX_LEVEL)
    if target_level >= MAX_LEVEL:
        return 0
    var n: int = target_level - 1
    return 120 + n * 55 + n * n * 4

func add_xp_v68(amount: int, reason: String = "Progress", category: String = "general") -> int:
    if amount <= 0 or level >= MAX_LEVEL:
        return 0
    var multiplier: float = _xp_multiplier_v68(category)
    var granted: int = maxi(1, int(round(float(amount) * multiplier)))
    xp_in_level += granted
    var leveled: bool = false
    while level < MAX_LEVEL:
        var needed: int = xp_to_next_level_v68(level)
        if needed <= 0 or xp_in_level < needed:
            break
        xp_in_level -= needed
        level += 1
        talent_points += 1
        if level % 2 == 0:
            stat_points += 1
        leveled = true
        level_up.emit(level)
        progression_feedback.emit("LEVEL %d — +1 Talent Point%s" % [level, " • +1 Stat Point" if level % 2 == 0 else ""])
    if level >= MAX_LEVEL:
        xp_in_level = 0
    if not leveled:
        progression_feedback.emit("+%d XP — %s" % [granted, reason])
    progression_changed.emit()
    _request_autosave_v68("Progression XP")
    return granted

func award_event_once_v68(event_key: String, base_xp: int, reason: String, category: String = "general") -> bool:
    if event_key.is_empty() or bool(claimed_xp_events.get(event_key, false)):
        return false
    claimed_xp_events[event_key] = true
    add_xp_v68(base_xp, reason, category)
    return true

func award_event_for_peer_v68(peer_id: int, event_key: String, base_xp: int, reason: String, category: String = "general") -> void:
    if peer_id <= 0:
        return
    if not _network_online_v68() or peer_id == _local_peer_id_v68():
        award_event_once_v68(event_key, base_xp, reason, category)
        return
    if _is_host_v68():
        _receive_progression_award_v68.rpc_id(peer_id, event_key, base_xp, reason, category)

@rpc("authority", "call_remote", "reliable", 68)
func _receive_progression_award_v68(event_key: String, base_xp: int, reason: String, category: String) -> void:
    award_event_once_v68(event_key, base_xp, reason, category)

func unlock_knowledge_v68(knowledge_id: String, announce: bool = true) -> bool:
    if not KNOWLEDGE.has(knowledge_id) or bool(knowledge_unlocked_ids.get(knowledge_id, false)):
        return false
    knowledge_unlocked_ids[knowledge_id] = true
    knowledge_unlocked.emit(knowledge_id)
    progression_changed.emit()
    if announce:
        var data: Dictionary = Dictionary(KNOWLEDGE.get(knowledge_id, {}))
        progression_feedback.emit("KNOWLEDGE — %s" % str(data.get("title", knowledge_id)))
    _request_autosave_v68("Knowledge discovered")
    return true

func unlock_knowledge_for_peer_v68(peer_id: int, knowledge_id: String) -> void:
    if peer_id <= 0 or not KNOWLEDGE.has(knowledge_id):
        return
    if not _network_online_v68() or peer_id == _local_peer_id_v68():
        unlock_knowledge_v68(knowledge_id)
        return
    if _is_host_v68():
        _receive_knowledge_unlock_v68.rpc_id(peer_id, knowledge_id)

@rpc("authority", "call_remote", "reliable", 68)
func _receive_knowledge_unlock_v68(knowledge_id: String) -> void:
    unlock_knowledge_v68(knowledge_id)

func record_evidence_for_peer_v68(peer_id: int, evidence_id: String) -> void:
    var event_key: String = "evidence:%s" % evidence_id
    award_event_for_peer_v68(peer_id, event_key, 30, "Evidence logged", "evidence")
    var knowledge_id: String = str(EVIDENCE_KNOWLEDGE.get(evidence_id, ""))
    if not knowledge_id.is_empty():
        unlock_knowledge_for_peer_v68(peer_id, knowledge_id)

func record_case_synthesis_for_peer_v68(peer_id: int) -> void:
    award_event_for_peer_v68(peer_id, "case_synthesis:forest", 100, "Forest clues synthesized", "evidence")
    unlock_knowledge_for_peer_v68(peer_id, "mine_route")

func record_first_craft_v68(recipe_id: String) -> void:
    if recipe_id.is_empty():
        return
    if award_event_once_v68("craft:first:%s" % recipe_id, 25, "First craft: %s" % recipe_id, "craft"):
        match recipe_id:
            "bandage": unlock_knowledge_v68("field_medicine")
            "flashlight_battery": unlock_knowledge_v68("electrical_salvage")
            "hunting_bow", "arrow_pack", "hunting_knife": unlock_knowledge_v68("wildlife_anatomy")
            "anti_radiation_tower": unlock_knowledge_v68("research_anomaly")

func spend_stat_point_v68(stat_id: String) -> bool:
    if stat_points <= 0 or stat_id not in STAT_IDS:
        return false
    var current: int = int(stats.get(stat_id, BASE_STAT_VALUE))
    if current >= MAX_STAT_VALUE:
        return false
    stats[stat_id] = current + 1
    stat_points -= 1
    progression_changed.emit()
    progression_feedback.emit("%s increased to %d" % [str(STAT_NAMES.get(stat_id, stat_id)), current + 1])
    _request_autosave_v68("Stat allocated")
    return true

func unlock_talent_v68(talent_id: String) -> bool:
    if talent_points <= 0 or not TALENTS.has(talent_id):
        return false
    var data: Dictionary = Dictionary(TALENTS.get(talent_id, {}))
    if level < int(data.get("min_level", 1)):
        return false
    var current: int = int(talent_ranks.get(talent_id, 0))
    var max_rank: int = maxi(1, int(data.get("max_rank", 1)))
    if current >= max_rank:
        return false
    var required: String = str(data.get("requires", ""))
    if not required.is_empty() and int(talent_ranks.get(required, 0)) < int(data.get("requires_rank", 1)):
        return false
    talent_ranks[talent_id] = current + 1
    talent_points -= 1
    progression_changed.emit()
    progression_feedback.emit("TALENT — %s %d/%d" % [str(data.get("name", talent_id)), current + 1, max_rank])
    _request_autosave_v68("Talent unlocked")
    return true

func get_level_v68() -> int:
    return level

func get_xp_v68() -> int:
    return xp_in_level

func get_talent_points_v68() -> int:
    return talent_points

func get_stat_points_v68() -> int:
    return stat_points

func get_stat_v68(stat_id: String) -> int:
    return clampi(int(stats.get(stat_id, BASE_STAT_VALUE)), 0, MAX_STAT_VALUE)

func get_talent_rank_v68(talent_id: String) -> int:
    return maxi(0, int(talent_ranks.get(talent_id, 0)))

func has_talent_v68(talent_id: String, rank: int = 1) -> bool:
    return get_talent_rank_v68(talent_id) >= maxi(1, rank)

func has_knowledge_v68(knowledge_id: String) -> bool:
    return bool(knowledge_unlocked_ids.get(knowledge_id, false))

func get_stats_v68() -> Dictionary:
    return stats.duplicate(true)

func get_talents_v68() -> Dictionary:
    return talent_ranks.duplicate(true)

func get_knowledge_v68() -> Dictionary:
    return knowledge_unlocked_ids.duplicate(true)

func get_talent_definition_v68(talent_id: String) -> Dictionary:
    return Dictionary(TALENTS.get(talent_id, {})).duplicate(true)

func get_knowledge_definition_v68(knowledge_id: String) -> Dictionary:
    return Dictionary(KNOWLEDGE.get(knowledge_id, {})).duplicate(true)

func get_stat_name_v68(stat_id: String) -> String:
    return str(STAT_NAMES.get(stat_id, stat_id.capitalize()))

func get_stat_description_v68(stat_id: String) -> String:
    return str(STAT_DESCRIPTIONS.get(stat_id, ""))

func get_max_carry_bonus_v68() -> float:
    return float(get_stat_v68("endurance")) * 0.10 + float(get_talent_rank_v68("load_bearing")) * 1.0

func get_loaded_ratio_v68() -> float:
    return 0.75 if has_talent_v68("pack_discipline") else 0.70

func get_sprint_drain_multiplier_v68() -> float:
    return maxf(0.75, 1.0 - float(get_talent_rank_v68("runner")) * 0.04)

func get_noise_multiplier_v68() -> float:
    return maxf(0.75, 1.0 - float(get_talent_rank_v68("quiet_steps")) * 0.04)

func get_metabolism_multiplier_v68() -> float:
    var fortitude_reduction: float = float(get_stat_v68("fortitude")) * 0.005
    var talent_reduction: float = float(get_talent_rank_v68("efficient_metabolism")) * 0.03
    return clampf(1.0 - fortitude_reduction - talent_reduction, 0.75, 1.0)

func get_movement_multiplier_v68() -> float:
    var stat_bonus: float = float(get_stat_v68("fitness")) * 0.002
    var talent_bonus: float = float(get_talent_rank_v68("pathfinder")) * 0.005
    return clampf(1.0 + stat_bonus + talent_bonus, 1.0, 1.06)

func get_panic_multiplier_v68() -> float:
    var focus_reduction: float = float(get_stat_v68("focus")) * 0.01
    var talent_reduction: float = float(get_talent_rank_v68("steady_hands")) * 0.05
    return clampf(1.0 - focus_reduction - talent_reduction, 0.65, 1.0)

func get_consumable_duration_multiplier_v68() -> float:
    var dexterity_reduction: float = float(get_stat_v68("dexterity")) * 0.005
    var medic_reduction: float = float(get_talent_rank_v68("field_medic")) * 0.08
    return clampf(1.0 - dexterity_reduction - medic_reduction, 0.70, 1.0)

func get_technical_duration_multiplier_v68() -> float:
    var dexterity_reduction: float = float(get_stat_v68("dexterity")) * 0.005
    var repair_reduction: float = float(get_talent_rank_v68("quick_repair")) * 0.06
    return clampf(1.0 - dexterity_reduction - repair_reduction, 0.70, 1.0)

func get_generator_fuel_effectiveness_v68() -> float:
    return 1.0 + float(get_talent_rank_v68("fuel_economy")) * 0.06

func get_evidence_xp_multiplier_v68() -> float:
    return 1.0 + float(get_talent_rank_v68("evidence_analyst")) * 0.10

func get_knowledge_hint_level_v68() -> int:
    var pattern: int = get_talent_rank_v68("pattern_recognition")
    var familiarity: int = get_talent_rank_v68("threat_familiarity")
    return clampi(pattern + familiarity, 0, 4)

func get_progression_summary_v68() -> Dictionary:
    return {
        "level": level,
        "xp": xp_in_level,
        "xp_to_next": xp_to_next_level_v68(),
        "talent_points": talent_points,
        "stat_points": stat_points,
        "stats": stats.duplicate(true),
        "talents": talent_ranks.duplicate(true),
        "knowledge": knowledge_unlocked_ids.duplicate(true),
        "knowledge_count": knowledge_unlocked_ids.size(),
        "knowledge_total": KNOWLEDGE_ORDER.size()
    }

func get_save_state() -> Dictionary:
    return {
        "version": 68,
        "level": level,
        "xp_in_level": xp_in_level,
        "talent_points": talent_points,
        "stat_points": stat_points,
        "stats": stats.duplicate(true),
        "talent_ranks": talent_ranks.duplicate(true),
        "knowledge": knowledge_unlocked_ids.duplicate(true),
        "claimed_xp_events": claimed_xp_events.duplicate(true),
        "active_night_start_day": active_night_start_day
    }

func restore_save_state(state: Dictionary) -> void:
    restoring_state = true
    level = clampi(int(state.get("level", 1)), 1, MAX_LEVEL)
    xp_in_level = maxi(0, int(state.get("xp_in_level", 0)))
    talent_points = maxi(0, int(state.get("talent_points", 0)))
    stat_points = maxi(0, int(state.get("stat_points", 0)))

    _initialize_stats_v68()
    var saved_stats_value: Variant = state.get("stats", {})
    if saved_stats_value is Dictionary:
        var saved_stats: Dictionary = Dictionary(saved_stats_value)
        for stat_id: String in STAT_IDS:
            stats[stat_id] = clampi(int(saved_stats.get(stat_id, 0)), 0, MAX_STAT_VALUE)

    talent_ranks.clear()
    var saved_talents_value: Variant = state.get("talent_ranks", {})
    if saved_talents_value is Dictionary:
        var saved_talents: Dictionary = Dictionary(saved_talents_value)
        for talent_id: String in TALENT_ORDER:
            var max_rank: int = int(Dictionary(TALENTS.get(talent_id, {})).get("max_rank", 1))
            talent_ranks[talent_id] = clampi(int(saved_talents.get(talent_id, 0)), 0, max_rank)

    knowledge_unlocked_ids = _sanitize_bool_dictionary_v68(state.get("knowledge", {}), KNOWLEDGE)
    claimed_xp_events = _sanitize_claims_v68(state.get("claimed_xp_events", {}))
    active_night_start_day = int(state.get("active_night_start_day", -1))
    restoring_state = false
    progression_changed.emit()

func reset_progression_v68(emit_change: bool = true) -> void:
    level = 1
    xp_in_level = 0
    talent_points = 0
    stat_points = 0
    _initialize_stats_v68()
    talent_ranks.clear()
    for talent_id: String in TALENT_ORDER:
        talent_ranks[talent_id] = 0
    knowledge_unlocked_ids.clear()
    claimed_xp_events.clear()
    last_scene_path = ""
    active_night_start_day = -1
    previous_generator_running = false
    player_baselines.clear()
    last_player_id = 0
    if emit_change:
        progression_changed.emit()

func _initialize_stats_v68() -> void:
    stats.clear()
    for stat_id: String in STAT_IDS:
        stats[stat_id] = BASE_STAT_VALUE

func _xp_multiplier_v68(category: String) -> float:
    if category == "evidence":
        return get_evidence_xp_multiplier_v68()
    return 1.0

func _apply_runtime_modifiers_v68(player: CharacterBody3D) -> void:
    var player_id: int = int(player.get_instance_id())
    if player_id != last_player_id or not player_baselines.has(player_id):
        last_player_id = player_id
        player_baselines[player_id] = {
            "move_speed": float(player.get("move_speed")),
            "max_stamina": float(player.get("max_stamina")),
            "stamina_regen": float(player.get("stamina_regen_per_second")),
            "hunger_drain": float(player.get("hunger_drain_per_second")),
            "thirst_drain": float(player.get("thirst_drain_per_second"))
        }
    var baseline: Dictionary = Dictionary(player_baselines.get(player_id, {}))
    if baseline.is_empty():
        return

    var new_max_stamina: float = float(baseline.get("max_stamina", 100.0)) + float(get_stat_v68("endurance"))
    player.set("max_stamina", new_max_stamina)
    player.set("stamina", minf(float(player.get("stamina")), new_max_stamina))
    player.set("stamina_regen_per_second", float(baseline.get("stamina_regen", 18.0)) * (1.0 + float(get_stat_v68("endurance")) * 0.004))
    player.set("move_speed", float(baseline.get("move_speed", 4.0)) * get_movement_multiplier_v68())
    player.set("hunger_drain_per_second", float(baseline.get("hunger_drain", 0.055)) * get_metabolism_multiplier_v68())
    player.set("thirst_drain_per_second", float(baseline.get("thirst_drain", 0.082)) * get_metabolism_multiplier_v68())

func _monitor_scene_discovery_v68() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var path: String = scene.scene_file_path
    if path.is_empty() or path == last_scene_path:
        return
    last_scene_path = path
    if SCENE_XP.has(path):
        award_event_once_v68("scene:%s" % path, int(SCENE_XP.get(path, 20)), "Location discovered", "exploration")
    var knowledge_id: String = str(SCENE_KNOWLEDGE.get(path, ""))
    if not knowledge_id.is_empty():
        unlock_knowledge_v68(knowledge_id, false)

func _monitor_threat_knowledge_v68(player: CharacterBody3D) -> void:
    var darkness: Node3D = get_tree().get_first_node_in_group("darkness_creature") as Node3D
    if darkness != null and player.global_position.distance_to(darkness.global_position) <= 18.0:
        if unlock_knowledge_v68("darkness_presence"):
            award_event_once_v68("observe:darkness", 20, "Darkness observed", "knowledge")
        if get_knowledge_hint_level_v68() >= 2:
            unlock_knowledge_v68("darkness_light_rule", false)

    var scene: Node = get_tree().current_scene
    var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D if scene != null else null
    if tenant != null and player.global_position.distance_to(tenant.global_position) <= 18.0:
        if unlock_knowledge_v68("tenant_presence"):
            award_event_once_v68("observe:tenant", 20, "Tenant observed", "knowledge")
        if get_knowledge_hint_level_v68() >= 2:
            unlock_knowledge_v68("tenant_light_rule", false)

func _monitor_night_survival_v68(player: CharacterBody3D) -> void:
    if bool(player.get("is_dead")):
        return
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return
    var minutes: float = float(outside.call("get_time_minutes")) if outside.has_method("get_time_minutes") else float(outside.get("game_minutes"))
    var day_index: int = int(outside.get("day_index"))
    if minutes >= 1200.0:
        active_night_start_day = day_index
    elif minutes < 300.0 and active_night_start_day < 0:
        active_night_start_day = maxi(1, day_index - 1)
    elif minutes >= 300.0 and minutes <= 480.0 and active_night_start_day >= 0:
        var night_key: int = active_night_start_day
        active_night_start_day = -1
        if award_event_once_v68("survive_night:%d" % night_key, 75, "Night survived", "survival"):
            unlock_knowledge_v68("night_survival")

func _monitor_generator_v68() -> void:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        previous_generator_running = false
        return
    var running: bool = bool(shelter.get("generator_running"))
    if running and not previous_generator_running:
        var outside: Node = get_node_or_null("/root/OutsideDirector")
        var day_index: int = int(outside.get("day_index")) if outside != null else 1
        if award_event_once_v68("generator_start:day:%d" % day_index, 40, "Shelter generator online", "survival"):
            unlock_knowledge_v68("generator_maintenance")
    previous_generator_running = running

func _sanitize_bool_dictionary_v68(value: Variant, allowed: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    if not (value is Dictionary):
        return result
    var source: Dictionary = Dictionary(value)
    for key_variant: Variant in source.keys():
        var key: String = str(key_variant)
        if allowed.has(key) and bool(source.get(key_variant, false)):
            result[key] = true
    return result

func _sanitize_claims_v68(value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if not (value is Dictionary):
        return result
    var source: Dictionary = Dictionary(value)
    for key_variant: Variant in source.keys():
        var key: String = str(key_variant).left(160)
        if not key.is_empty() and bool(source.get(key_variant, false)):
            result[key] = true
    return result

func _request_autosave_v68(reason: String) -> void:
    if restoring_state:
        return
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", reason)

func _network_online_v68() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_host_v68() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _local_peer_id_v68() -> int:
    if not _network_online_v68():
        return 1
    return multiplayer.get_unique_id()

func _local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback
