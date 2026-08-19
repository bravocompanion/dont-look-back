extends "res://scripts/shelter_chest.gd"

func get_interaction_text() -> String:
    return "Open Shared Stash"

func interact() -> void:
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("open_stash"):
        stash.call("open_stash", self)
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "Shared Stash UI is unavailable."
