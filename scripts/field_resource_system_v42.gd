extends "res://scripts/field_resource_system_v41.gd"

# v0.56 co-op economy scaling. Base world supply stays unchanged for solo/duo.
# Parties of 3 and 4 receive deterministic extra shared pickups at existing
# POIs. Bonus nodes disappear again if the party shrinks before they are
# claimed, so a solo player cannot keep unclaimed four-player supply.

const MENU_SCENE_PATH_V56: String = "res://scenes/main_menu_ranger.tscn"
const BONUS_REFRESH_SECONDS_V56: float = 0.75

const PARTY3_FOREST_V56: Array[Dictionary] = [
    {"name":"V56_P3_HouseClothA", "id":"cloth", "label":"Cloth", "pos":Vector3(-72.8, 0.05, -160.5)},
    {"name":"V56_P3_HouseClothB", "id":"cloth", "label":"Cloth", "pos":Vector3(-66.8, 0.05, -152.0)},
    {"name":"V56_P3_HousePlasticA", "id":"plastic_sheet", "label":"Plastic Sheet", "pos":Vector3(-74.5, 0.05, -151.8)},
    {"name":"V56_P3_GasFuelA", "id":"generator_fuel", "label":"Fuel Can", "pos":Vector3(81.5, 0.05, -231.0)},
    {"name":"V56_P3_GasElectronicsA", "id":"electronics", "label":"Electronics", "pos":Vector3(71.5, 0.05, -231.0)},
    {"name":"V56_P3_GasCopperA", "id":"copper_wire", "label":"Copper Wire", "pos":Vector3(82.2, 0.05, -222.5)},
    {"name":"V56_P3_WarehouseScrapA", "id":"scrap", "label":"Scrap", "pos":Vector3(-80.0, 0.05, -287.0)},
    {"name":"V56_P3_WarehouseScrapB", "id":"scrap", "label":"Scrap", "pos":Vector3(-66.0, 0.05, -283.0)},
    {"name":"V56_P3_WarehouseLeadA", "id":"lead_plate", "label":"Lead Plate", "pos":Vector3(-77.5, 0.05, -296.0)},
    {"name":"V56_P3_WarehouseLeadB", "id":"lead_plate", "label":"Lead Plate", "pos":Vector3(-68.5, 0.05, -296.0)},
    {"name":"V56_P3_WarehouseFilterA", "id":"filter", "label":"Industrial Filter", "pos":Vector3(-72.0, 0.05, -296.5)},
    {"name":"V56_P3_WarehouseElectronicsA", "id":"electronics", "label":"Electronics", "pos":Vector3(-64.5, 0.05, -285.5)}
]

const PARTY4_FOREST_V56: Array[Dictionary] = [
    {"name":"V56_P4_HouseClothA", "id":"cloth", "label":"Cloth", "pos":Vector3(-75.0, 0.05, -159.5)},
    {"name":"V56_P4_HouseRubberA", "id":"rubber", "label":"Rubber", "pos":Vector3(-64.8, 0.05, -159.0)},
    {"name":"V56_P4_GasFuelA", "id":"generator_fuel", "label":"Fuel Can", "pos":Vector3(69.2, 0.05, -226.0)},
    {"name":"V56_P4_GasElectronicsA", "id":"electronics", "label":"Electronics", "pos":Vector3(80.8, 0.05, -220.8)},
    {"name":"V56_P4_WarehouseScrapA", "id":"scrap", "label":"Scrap", "pos":Vector3(-80.5, 0.05, -292.5)},
    {"name":"V56_P4_WarehouseScrapB", "id":"scrap", "label":"Scrap", "pos":Vector3(-64.5, 0.05, -292.5)},
    {"name":"V56_P4_WarehouseLeadA", "id":"lead_plate", "label":"Lead Plate", "pos":Vector3(-76.0, 0.05, -298.0)},
    {"name":"V56_P4_WarehouseFilterA", "id":"filter", "label":"Industrial Filter", "pos":Vector3(-69.5, 0.05, -298.0)},
    {"name":"V56_P4_WarehouseCopperA", "id":"copper_wire", "label":"Copper Wire", "pos":Vector3(-65.0, 0.05, -295.5)}
]

const PARTY3_MINE_V56: Array[Dictionary] = [
    {"name":"V56_P3_MineLeadA", "id":"lead_plate", "label":"Lead Plate", "pos":Vector3(2.6, 0.05, -63.0)},
    {"name":"V56_P3_MineScrapA", "id":"scrap", "label":"Scrap", "pos":Vector3(-2.4, 0.05, -31.0)}
]

const PARTY4_MINE_V56: Array[Dictionary] = [
    {"name":"V56_P4_MineLeadA", "id":"lead_plate", "label":"Lead Plate", "pos":Vector3(-2.6, 0.05, -64.0)},
    {"name":"V56_P4_MineFilterA", "id":"filter", "label":"Industrial Filter", "pos":Vector3(2.4, 0.05, -46.0)}
]

var bonus_refresh_timer_v56: float = 0.0
var last_party_tier_v56: int = -1
var last_bonus_scene_id_v56: int = 0

func _process(delta: float) -> void:
    super._process(delta)

    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path == MENU_SCENE_PATH_V56:
        return
    if scene.scene_file_path != FOREST_SCENE_PATH and scene.scene_file_path != MINE_SCENE_PATH:
        return

    bonus_refresh_timer_v56 -= delta
    var scene_id: int = int(scene.get_instance_id())
    var tier: int = _party_tier_v56()
    if bonus_refresh_timer_v56 > 0.0 and scene_id == last_bonus_scene_id_v56 and tier == last_party_tier_v56:
        return

    bonus_refresh_timer_v56 = BONUS_REFRESH_SECONDS_V56
    last_bonus_scene_id_v56 = scene_id
    last_party_tier_v56 = tier
    _refresh_bonus_resources_v56(scene, tier)

func _party_tier_v56() -> int:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if not online:
        return 1
    var size: int = 1 + multiplayer.get_peers().size()
    if size >= 4:
        return 4
    if size >= 3:
        return 3
    return 2

func _refresh_bonus_resources_v56(scene: Node, tier: int) -> void:
    var tier3: Array[Dictionary] = PARTY3_FOREST_V56 if scene.scene_file_path == FOREST_SCENE_PATH else PARTY3_MINE_V56
    var tier4: Array[Dictionary] = PARTY4_FOREST_V56 if scene.scene_file_path == FOREST_SCENE_PATH else PARTY4_MINE_V56

    _set_bonus_tier_v56(scene, tier3, tier >= 3)
    _set_bonus_tier_v56(scene, tier4, tier >= 4)

func _set_bonus_tier_v56(scene: Node, specs: Array[Dictionary], enabled: bool) -> void:
    for data: Dictionary in specs:
        var node_name: String = str(data.get("name", ""))
        if node_name.is_empty():
            continue

        var existing: Node = scene.get_node_or_null(NodePath(node_name))
        if enabled:
            if existing != null:
                continue
            _spawn(
                scene,
                node_name,
                str(data.get("id", "scrap")),
                str(data.get("label", "Supply")),
                Vector3(data.get("pos", Vector3.ZERO))
            )
            continue

        # Claimed bonus nodes are already gone and remain recorded by SaveSystem.
        # Only unclaimed visible bonus supply is removed when the party shrinks.
        if existing != null and is_instance_valid(existing):
            existing.queue_free()
