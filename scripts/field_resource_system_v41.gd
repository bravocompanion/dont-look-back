extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const MINE_SCENE_PATH: String = "res://scenes/mine.tscn"
const PICKUP_SCRIPT_PATH: String = "res://scripts/survival_pickup.gd"

var configured_scene_id: int = 0
var pickup_script: Script = null

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    pickup_script = load(PICKUP_SCRIPT_PATH) as Script

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_id: int = int(scene.get_instance_id())
    if scene_id == configured_scene_id:
        return
    configured_scene_id = scene_id
    call_deferred("_configure_scene", scene)

func _configure_scene(scene: Node) -> void:
    await get_tree().process_frame
    await get_tree().process_frame
    if scene == null or not is_instance_valid(scene) or get_tree().current_scene != scene:
        return
    if scene.scene_file_path == FOREST_SCENE_PATH:
        _configure_forest(scene)
    elif scene.scene_file_path == MINE_SCENE_PATH:
        _configure_mine(scene)

func _configure_forest(scene: Node) -> void:
    # Abandoned House: early protection materials. Enough for a raincoat if the
    # team prioritizes it, but not enough for every late-game recipe.
    _spawn(scene, "V41_HouseClothA", "cloth", "Cloth", Vector3(-72.0, 0.05, -153.0))
    _spawn(scene, "V41_HouseClothB", "cloth", "Cloth", Vector3(-69.5, 0.05, -157.0))
    _spawn(scene, "V41_HouseClothC", "cloth", "Cloth", Vector3(-67.5, 0.05, -154.5))
    _spawn(scene, "V41_HouseClothD", "cloth", "Cloth", Vector3(-74.0, 0.05, -158.0))
    _spawn(scene, "V41_HousePlasticA", "plastic_sheet", "Plastic Sheet", Vector3(-68.0, 0.05, -151.5))
    _spawn(scene, "V41_HousePlasticB", "plastic_sheet", "Plastic Sheet", Vector3(-71.0, 0.05, -160.0))
    _spawn(scene, "V41_HousePlasticC", "plastic_sheet", "Plastic Sheet", Vector3(-66.5, 0.05, -158.5))
    _spawn(scene, "V41_HouseRubberA", "rubber", "Rubber", Vector3(-73.0, 0.05, -151.0))
    _spawn(scene, "V41_HouseRubberB", "rubber", "Rubber", Vector3(-65.5, 0.05, -156.0))
    _spawn(scene, "V41_HouseScrapA", "scrap", "Scrap", Vector3(-70.0, 0.05, -150.0))
    _spawn(scene, "V41_HouseScrapB", "scrap", "Scrap", Vector3(-75.0, 0.05, -155.0))

    # Old Gas Station: power and electrical salvage.
    _spawn(scene, "V41_GasFuelA", "generator_fuel", "Fuel Can", Vector3(74.0, 0.05, -222.0))
    _spawn(scene, "V41_GasFuelB", "generator_fuel", "Fuel Can", Vector3(79.0, 0.05, -229.0))
    _spawn(scene, "V41_GasRubberA", "rubber", "Rubber", Vector3(73.0, 0.05, -227.0))
    _spawn(scene, "V41_GasRubberB", "rubber", "Rubber", Vector3(80.0, 0.05, -224.0))
    _spawn(scene, "V41_GasElectronicsA", "electronics", "Electronics", Vector3(77.0, 0.05, -221.5))
    _spawn(scene, "V41_GasElectronicsB", "electronics", "Electronics", Vector3(75.0, 0.05, -230.0))
    _spawn(scene, "V41_GasCopperA", "copper_wire", "Copper Wire", Vector3(81.0, 0.05, -228.0))
    _spawn(scene, "V41_GasCopperB", "copper_wire", "Copper Wire", Vector3(72.0, 0.05, -224.0))
    _spawn(scene, "V41_GasScrapA", "scrap", "Scrap", Vector3(78.0, 0.05, -232.0))
    _spawn(scene, "V41_GasScrapB", "scrap", "Scrap", Vector3(70.5, 0.05, -229.0))

    # Warehouse: key Day-2 preparation cache. This is the main source for the
    # powered anti-radiation tower and radiation suit.
    _spawn(scene, "V41_WarehouseScrapA", "scrap", "Scrap", Vector3(-75.0, 0.05, -283.0))
    _spawn(scene, "V41_WarehouseScrapB", "scrap", "Scrap", Vector3(-72.0, 0.05, -282.0))
    _spawn(scene, "V41_WarehouseScrapC", "scrap", "Scrap", Vector3(-69.0, 0.05, -283.0))
    _spawn(scene, "V41_WarehouseScrapD", "scrap", "Scrap", Vector3(-76.0, 0.05, -287.0))
    _spawn(scene, "V41_WarehouseScrapE", "scrap", "Scrap", Vector3(-73.0, 0.05, -289.0))
    _spawn(scene, "V41_WarehouseScrapF", "scrap", "Scrap", Vector3(-70.0, 0.05, -290.0))
    _spawn(scene, "V41_WarehouseScrapG", "scrap", "Scrap", Vector3(-67.0, 0.05, -287.0))
    _spawn(scene, "V41_WarehouseScrapH", "scrap", "Scrap", Vector3(-78.0, 0.05, -291.0))
    _spawn(scene, "V41_WarehouseElectronicsA", "electronics", "Electronics", Vector3(-68.0, 0.05, -281.0))
    _spawn(scene, "V41_WarehouseElectronicsB", "electronics", "Electronics", Vector3(-66.0, 0.05, -285.0))
    _spawn(scene, "V41_WarehouseElectronicsC", "electronics", "Electronics", Vector3(-71.0, 0.05, -292.0))
    _spawn(scene, "V41_WarehouseLeadA", "lead_plate", "Lead Plate", Vector3(-79.0, 0.05, -284.0))
    _spawn(scene, "V41_WarehouseLeadB", "lead_plate", "Lead Plate", Vector3(-79.0, 0.05, -289.0))
    _spawn(scene, "V41_WarehouseLeadC", "lead_plate", "Lead Plate", Vector3(-74.5, 0.05, -293.0))
    _spawn(scene, "V41_WarehouseLeadD", "lead_plate", "Lead Plate", Vector3(-69.0, 0.05, -294.0))
    _spawn(scene, "V41_WarehouseCopperA", "copper_wire", "Copper Wire", Vector3(-65.0, 0.05, -288.0))
    _spawn(scene, "V41_WarehouseCopperB", "copper_wire", "Copper Wire", Vector3(-65.0, 0.05, -292.0))
    _spawn(scene, "V41_WarehouseFilterA", "filter", "Industrial Filter", Vector3(-77.0, 0.05, -294.0))
    _spawn(scene, "V41_WarehouseFilterB", "filter", "Industrial Filter", Vector3(-67.0, 0.05, -295.0))

    # Water pump: backup filters and waterproofing material.
    _spawn(scene, "V41_PumpFilterA", "filter", "Industrial Filter", Vector3(60.0, 0.05, -330.0))
    _spawn(scene, "V41_PumpFilterB", "filter", "Industrial Filter", Vector3(64.0, 0.05, -334.0))
    _spawn(scene, "V41_PumpPlasticA", "plastic_sheet", "Plastic Sheet", Vector3(59.0, 0.05, -335.0))
    _spawn(scene, "V41_PumpPlasticB", "plastic_sheet", "Plastic Sheet", Vector3(65.0, 0.05, -329.0))

func _configure_mine(scene: Node) -> void:
    # Deep reserves reward entering the mine after the initial Day-2 preparation.
    _spawn(scene, "V41_MineLeadA", "lead_plate", "Lead Plate", Vector3(-2.0, 0.05, -14.0))
    _spawn(scene, "V41_MineLeadB", "lead_plate", "Lead Plate", Vector3(2.0, 0.05, -28.0))
    _spawn(scene, "V41_MineLeadC", "lead_plate", "Lead Plate", Vector3(-2.5, 0.05, -48.0))
    _spawn(scene, "V41_MineElectronicsA", "electronics", "Electronics", Vector3(2.2, 0.05, -36.0))
    _spawn(scene, "V41_MineElectronicsB", "electronics", "Electronics", Vector3(-2.0, 0.05, -58.0))
    _spawn(scene, "V41_MineScrapA", "scrap", "Scrap", Vector3(2.5, 0.05, -20.0))
    _spawn(scene, "V41_MineScrapB", "scrap", "Scrap", Vector3(-2.2, 0.05, -39.0))
    _spawn(scene, "V41_MineFilterA", "filter", "Industrial Filter", Vector3(2.0, 0.05, -54.0))

func _spawn(scene: Node, node_name: String, item_id: String, display_name: String, world_position: Vector3) -> void:
    if pickup_script == null or scene.get_node_or_null(NodePath(node_name)) != null:
        return
    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../Player/HUD/Objective"))
    pickup.position = world_position
    scene.add_child(pickup)
