extends StaticBody3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var director: Node = get_node_or_null("/root/ShelterSystem")
    if director != null and director.has_method("get_campfire_percent"):
        var percent: int = int(director.call("get_campfire_percent"))
        if percent > 0:
            return "Feed campfire (%d%%)" % percent
    return "Light campfire (Firewood/Wood)"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var director: Node = get_node_or_null("/root/ShelterSystem")
    if director == null or not director.has_method("fuel_campfire"):
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var network_client: bool = network != null and network.has_method("is_client") and bool(network.call("is_client"))
    if network_client:
        var objective: Label = player.get_node_or_null("HUD/Objective") as Label
        var counts: Dictionary = Dictionary(player.get("inventory_counts"))
        var action: String = ""
        if int(counts.get("firewood_bundle", 0)) > 0:
            action = "campfire_bundle"
        elif int(counts.get("wood", 0)) > 0:
            action = "campfire_wood"
        else:
            if objective != null:
                objective.text = "The campfire needs Wood or a Firewood Bundle."
            return

        if network.has_method("request_shared_shelter_action"):
            network.call("request_shared_shelter_action", action)
        return

    director.call("fuel_campfire", player)

func _build_visual() -> void:
    var base_material: StandardMaterial3D = StandardMaterial3D.new()
    base_material.albedo_color = Color(0.12, 0.10, 0.085, 1.0)
    base_material.roughness = 1.0

    for i: int in range(5):
        var stone_mesh: BoxMesh = BoxMesh.new()
        stone_mesh.size = Vector3(0.34, 0.20, 0.34)
        var stone: MeshInstance3D = MeshInstance3D.new()
        stone.mesh = stone_mesh
        stone.material_override = base_material
        var angle: float = TAU * float(i) / 5.0
        stone.position = Vector3(cos(angle) * 0.48, 0.10, sin(angle) * 0.48)
        stone.rotation.y = angle
        add_child(stone)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: CylinderShape3D = CylinderShape3D.new()
    shape.radius = 0.72
    shape.height = 0.35
    collision.shape = shape
    collision.position = Vector3(0.0, 0.18, 0.0)
    add_child(collision)
