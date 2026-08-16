class_name MineAssetRegistry
extends RefCounted

const PROP_SCENE := "res://assets/environment/mine/models/godot/Mines_Runtime.dae"
const MODULAR_SCENE := "res://assets/environment/mine/models/godot/Mines_Modu_Runtime.dae"
const INTERACTABLES := {
    "Generator": "generator",
    "Petrol_Can": "fuel",
    "Medical_box": "medical",
    "Locker": "hiding_spot",
    "Locker_01": "hiding_spot",
    "Locker_D": "hiding_door",
    "Locker_D_01": "hiding_door",
    "Elevator": "elevator",
    "Door_Elevator": "elevator_door",
    "Button": "elevator_button",
    "TNT": "explosive",
    "TNT_01": "explosive",
    "Detonator": "detonator",
    "Detonator_M": "detonator",
    "Mining_Helmet": "light_item",
    "Farol": "light_item",
    "Farol_M": "light_item",
    "Shovel": "tool",
    "Beak": "pickaxe",
    "Wagon": "mine_cart"
}

static func gameplay_role(mesh_name: String) -> String:
    if INTERACTABLES.has(mesh_name):
        return str(INTERACTABLES[mesh_name])
    if mesh_name.begins_with("Mine"):
        return "mine_module"
    if mesh_name.begins_with("Rails"):
        return "rail"
    if mesh_name.begins_with("Wood_"):
        return "wood_support"
    if mesh_name.begins_with("Lamp"):
        return "mine_lamp"
    if mesh_name.begins_with("Cables"):
        return "cable"
    if mesh_name.begins_with("Rock") or mesh_name.begins_with("Gravel"):
        return "debris"
    if mesh_name.begins_with("Barrel") or mesh_name.begins_with("Box"):
        return "storage_prop"
    if mesh_name.begins_with("Fence"):
        return "fence"
    return "environment_prop"

static func is_static_visual_role(role: String) -> bool:
    return role in [
        "mine_module", "rail", "wood_support", "mine_lamp", "cable", "debris",
        "storage_prop", "fence", "environment_prop"
    ]
