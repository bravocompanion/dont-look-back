extends StaticBody3D

func _ready() -> void:
    _build_visual()
    _build_collision()

func get_interaction_text() -> String:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return "Cooking rack"
    var director: Node = get_node_or_null("/root/ShelterSystem")
    var fire_percent: int = int(director.call("get_campfire_percent")) if director != null and director.has_method("get_campfire_percent") else 0
    if fire_percent <= 0:
        return "Cooking rack — light the campfire first"
    if player.has_method("has_item") and bool(player.call("has_item", "raw_meat")):
        return "Cook Raw Meat"
    if player.has_method("has_item") and bool(player.call("has_item", "raw_fish")):
        return "Cook Raw Fish"
    return "Cooking rack — no raw food"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    var director: Node = get_node_or_null("/root/ShelterSystem")
    var fire_percent: int = int(director.call("get_campfire_percent")) if director != null and director.has_method("get_campfire_percent") else 0
    if fire_percent <= 0:
        if objective != null:
            objective.text = "The cooking rack is cold. Light the campfire before cooking."
        return

    var source_id: String = ""
    var cooked_id: String = ""
    var cooked_name: String = ""
    if player.has_method("has_item") and bool(player.call("has_item", "raw_meat")):
        source_id = "raw_meat"
        cooked_id = "cooked_meat"
        cooked_name = "Cooked Meat"
    elif player.has_method("has_item") and bool(player.call("has_item", "raw_fish")):
        source_id = "raw_fish"
        cooked_id = "cooked_fish"
        cooked_name = "Cooked Fish"
    else:
        if objective != null:
            objective.text = "You have no Raw Meat or Raw Fish to cook."
        return

    if not bool(player.call("remove_item", source_id)):
        return
    if not bool(player.call("add_item", cooked_id, cooked_name)):
        player.call("add_item", source_id, "Raw Meat" if source_id == "raw_meat" else "Raw Fish")
        if objective != null:
            objective.text = "Inventory full. The raw food stays on the cooking rack."
        return

    if objective != null:
        objective.text = "%s is cooked over the campfire and is now safe to eat." % cooked_name

func _build_visual() -> void:
    var dark_material: StandardMaterial3D = StandardMaterial3D.new()
    dark_material.albedo_color = Color(0.12, 0.10, 0.08, 1.0)
    dark_material.roughness = 0.95

    for x: float in [-0.55, 0.55]:
        var post: MeshInstance3D = MeshInstance3D.new()
        var post_mesh: CylinderMesh = CylinderMesh.new()
        post_mesh.top_radius = 0.045
        post_mesh.bottom_radius = 0.055
        post_mesh.height = 1.15
        post.mesh = post_mesh
        post.material_override = dark_material
        post.position = Vector3(x, 0.58, 0.0)
        add_child(post)

    var bar: MeshInstance3D = MeshInstance3D.new()
    var bar_mesh: CylinderMesh = CylinderMesh.new()
    bar_mesh.top_radius = 0.04
    bar_mesh.bottom_radius = 0.04
    bar_mesh.height = 1.25
    bar.mesh = bar_mesh
    bar.material_override = dark_material
    bar.rotation.z = PI * 0.5
    bar.position = Vector3(0.0, 1.08, 0.0)
    add_child(bar)

func _build_collision() -> void:
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.35, 1.20, 0.55)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.60, 0.0)
    add_child(collision)
