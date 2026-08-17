extends StaticBody3D

var searched: bool = false

func _ready() -> void:
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

    var granted: PackedStringArray = PackedStringArray()
    if not bool(player.call("has_item", "hunting_bow")) and bool(player.call("add_item", "hunting_bow", "Hunting Bow")):
        granted.append("Hunting Bow")
    if not bool(player.call("has_item", "hunting_knife")) and bool(player.call("add_item", "hunting_knife", "Hunting Knife")):
        granted.append("Hunting Knife")
    if not bool(player.call("has_item", "fishing_rod")) and bool(player.call("add_item", "fishing_rod", "Fishing Rod")):
        granted.append("Fishing Rod")

    var arrows_added: int = 0
    for _index: int in range(8):
        if bool(player.call("add_item", "arrow", "Arrow")):
            arrows_added += 1
    if arrows_added > 0:
        granted.append("%d Arrows" % arrows_added)

    if granted.is_empty():
        var full_objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if full_objective != null:
            full_objective.text = "The ranger cache is useful, but your inventory has no room for its equipment."
        return

    searched = true
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "RANGER CACHE: %s. Kill prey with the bow, then harvest the carcass with the knife." % ", ".join(granted)

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
