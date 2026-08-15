extends StaticBody3D

var recipe_index: int = 0
var indicator_material: StandardMaterial3D

const RECIPE_NAMES: Array[String] = ["Firewood Bundle", "Improvised Battery", "Bandage"]

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    match recipe_index:
        0:
            return "Craft Firewood Bundle (2 Wood)"
        1:
            return "Craft Improvised Battery (1 Wood + 2 Scrap)"
        _:
            return "Craft Bandage (2 Cloth)"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    var crafted: bool = false

    match recipe_index:
        0:
            crafted = _craft_firewood(player)
            if objective != null:
                objective.text = "Crafted Firewood Bundle. Next: Improvised Battery." if crafted else "Need 2 Wood. Next: Improvised Battery."
        1:
            crafted = _craft_battery(player)
            if objective != null:
                objective.text = "Crafted Improvised Battery. Next: Bandage." if crafted else "Need 1 Wood + 2 Scrap. Next: Bandage."
        _:
            crafted = _craft_bandage(player)
            if objective != null:
                objective.text = "Crafted Bandage. Next: Firewood Bundle." if crafted else "Need 2 Cloth. Next: Firewood Bundle."

    recipe_index = (recipe_index + 1) % RECIPE_NAMES.size()
    _flash_indicator(crafted)

func _craft_firewood(player: CharacterBody3D) -> bool:
    if _item_count(player, "wood") < 2:
        return false
    if not _remove_many(player, "wood", 2):
        return false
    if not bool(player.call("add_item", "firewood_bundle", "Firewood Bundle")):
        _refund(player, "wood", "Wood", 2)
        return false
    return true

func _craft_battery(player: CharacterBody3D) -> bool:
    if _item_count(player, "wood") < 1 or _item_count(player, "scrap") < 2:
        return false
    if not _remove_many(player, "wood", 1):
        return false
    if not _remove_many(player, "scrap", 2):
        _refund(player, "wood", "Wood", 1)
        return false
    if not bool(player.call("add_item", "flashlight_battery", "Flashlight Battery")):
        _refund(player, "wood", "Wood", 1)
        _refund(player, "scrap", "Scrap", 2)
        return false
    return true

func _craft_bandage(player: CharacterBody3D) -> bool:
    if _item_count(player, "cloth") < 2:
        return false
    if not _remove_many(player, "cloth", 2):
        return false
    if not bool(player.call("add_item", "bandage", "Bandage")):
        _refund(player, "cloth", "Cloth", 2)
        return false
    return true

func _item_count(player: CharacterBody3D, item_id: String) -> int:
    var counts: Dictionary = Dictionary(player.get("inventory_counts"))
    return int(counts.get(item_id, 0))

func _remove_many(player: CharacterBody3D, item_id: String, amount: int) -> bool:
    if not player.has_method("remove_item"):
        return false
    if _item_count(player, item_id) < amount:
        return false
    for _index: int in range(amount):
        if not bool(player.call("remove_item", item_id)):
            return false
    return true

func _refund(player: CharacterBody3D, item_id: String, display_name: String, amount: int) -> void:
    if not player.has_method("add_item"):
        return
    for _index: int in range(amount):
        player.call("add_item", item_id, display_name)

func _flash_indicator(success: bool) -> void:
    if indicator_material == null:
        return
    indicator_material.albedo_color = Color(0.18, 0.62, 0.30, 1.0) if success else Color(0.62, 0.18, 0.10, 1.0)
    indicator_material.emission = Color(0.08, 0.48, 0.18, 1.0) if success else Color(0.48, 0.05, 0.02, 1.0)

func _build_visual() -> void:
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.7, 0.18, 0.72)

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.20, 0.13, 0.07, 1.0)
    body_material.roughness = 0.88

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.86, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.7, 1.0, 0.72)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.5, 0.0)
    add_child(collision)

    indicator_material = StandardMaterial3D.new()
    indicator_material.albedo_color = Color(0.22, 0.36, 0.20, 1.0)
    indicator_material.emission_enabled = true
    indicator_material.emission = Color(0.08, 0.24, 0.08, 1.0)
    indicator_material.emission_energy_multiplier = 1.8

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(0.48, 0.08, 0.08)
    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, 0.98, -0.34)
    add_child(indicator)
