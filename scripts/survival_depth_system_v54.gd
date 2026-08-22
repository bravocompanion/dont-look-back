extends "res://scripts/survival_depth_system.gd"

func boil_water(player: CharacterBody3D) -> bool:
    if player == null:
        return false

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null or not shelter.has_method("get_campfire_percent"):
        _set_objective(player, "The boiling pot needs the shelter campfire.")
        return false

    var fire_percent: int = int(shelter.call("get_campfire_percent"))
    if fire_percent <= 0:
        _set_objective(player, "Light the campfire before boiling water.")
        return false
    if not player.has_method("has_item") or not bool(player.call("has_item", "dirty_water")):
        _set_objective(player, "You have no Dirty Water to boil.")
        return false

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("can_accept_item"):
        if not bool(carry.call("can_accept_item", player, "bottled_water", 1)):
            _set_objective(player, "Clean Water carry limit reached. Store supplies before boiling more.")
            return false

    if not player.has_method("remove_item") or not bool(player.call("remove_item", "dirty_water")):
        return false

    var granted: bool = false
    if carry != null and carry.has_method("grant_item"):
        granted = bool(carry.call("grant_item", player, "bottled_water", "Clean Water", 1))
    elif player.has_method("add_item"):
        granted = bool(player.call("add_item", "bottled_water", "Clean Water"))

    if not granted:
        if player.has_method("add_item"):
            player.call("add_item", "dirty_water", "Dirty Water")
        _set_objective(player, "No room for Clean Water. The Dirty Water was not processed.")
        return false

    _set_objective(player, "You boil the Dirty Water into safe Clean Water.")
    return true
