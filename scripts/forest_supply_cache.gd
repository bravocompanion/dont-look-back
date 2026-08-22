extends StaticBody3D

var searched: bool = false

func _ready() -> void:
    _relocate_outside_ranger_safe_zone()
    _build_visual()
    _build_collision()

func get_interaction_text() -> String:
    return "Empty survival cache" if searched else "Search old ranger survival cache"

func interact() -> void:
    if searched:
        return
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("add_item"):
        return

    # v0.54 removes the free Hunting Bow and Hunting Knife. The cache gives a
    # fishing fallback, a few arrows to save for later, and partial materials;
    # hunting progression now requires scavenging and using the workbench.
    var granted: PackedStringArray = PackedStringArray()
    if not bool(player.call("has_item", "fishing_rod")) and _grant(player, "fishing_rod", "Fishing Rod", 1):
        granted.append("Fishing Rod")

    var arrows_added: int = _grant_count(player, "arrow", "Arrow", 4)
    if arrows_added > 0:
        granted.append("%d Arrows" % arrows_added)

    if _grant(player, "cloth", "Cloth", 1):
        granted.append("Cloth")
    if _grant(player, "scrap", "Scrap", 1):
        granted.append("Scrap")

    if granted.is_empty():
        var full_objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if full_objective != null:
            full_objective.text = "The ranger cache still has supplies, but your carry limits are full. Store something and return."
        return

    searched = true
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "RANGER CACHE: %s. Scavenge Wood, Cloth and Scrap, then craft a Hunting Bow and Hunting Knife at the workbench." % ", ".join(granted)

func _grant(player: CharacterBody3D, item_id: String, display_name: String, amount: int) -> bool:
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("grant_item"):
        return bool(carry.call("grant_item", player, item_id, display_name, amount))

    var granted: int = 0
    for _index: int in range(amount):
        if not bool(player.call("add_item", item_id, display_name)):
            break
        granted += 1
    return granted == amount

func _grant_count(player: CharacterBody3D, item_id: String, display_name: String, requested: int) -> int:
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    var granted: int = 0
    for _index: int in range(requested):
        var accepted: bool = false
        if carry != null and carry.has_method("grant_item"):
            accepted = bool(carry.call("grant_item", player, item_id, display_name, 1))
        else:
            accepted = bool(player.call("add_item", item_id, display_name))
        if not accepted:
            break
        granted += 1
    return granted

func _local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D
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

func _relocate_outside_ranger_safe_zone() -> void:
    var safe_zone: Node = get_node_or_null("/root/RangerSafeZone")
    if safe_zone == null or not safe_zone.has_method("is_position_safe") or not safe_zone.has_method("push_position_outside"):
        return
    if not bool(safe_zone.call("is_position_safe", global_position)):
        return
    var relocated: Variant = safe_zone.call("push_position_outside", global_position, 3.0)
    if relocated is Vector3:
        global_position = relocated

func _build_visual() -> void:
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.16, 0.19, 0.13, 1.0)
    material.roughness = 0.88

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.name = "CacheBody"
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(1.35, 0.70, 0.72)
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = Vector3(0.0, 0.35, 0.0)
    add_child(mesh_instance)

func _build_collision() -> void:
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.35, 0.70, 0.72)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.35, 0.0)
    add_child(collision)
