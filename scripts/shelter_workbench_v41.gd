extends "res://scripts/shelter_workbench.gd"

func get_interaction_text() -> String:
    return "Open Ranger Workbench"

func interact() -> void:
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("open_workbench"):
        crafting.call("open_workbench", self)
