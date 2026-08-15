extends StaticBody3D

@export var entry_id: String = "note"
@export var entry_title: String = "Unknown Note"
@export var entry_category: String = "NOTE"
@export_multiline var entry_body: String = ""

var collected: bool = false

func _ready() -> void:
    add_to_group("journal_note")
    _build_visual()
    call_deferred("_remove_if_discovered")

func get_interaction_text() -> String:
    return "Read %s" % entry_title

func interact() -> void:
    if collected:
        return

    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null or not journal.has_method("discover_entry"):
        return

    collected = true
    journal.call("discover_entry", entry_id, entry_title, entry_category, entry_body, true)

    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", "Journal entry discovered")

    queue_free()

func _remove_if_discovered() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("has_entry"):
        if bool(journal.call("has_entry", entry_id)):
            queue_free()

func _build_visual() -> void:
    var paper_material: StandardMaterial3D = StandardMaterial3D.new()
    paper_material.albedo_color = Color(0.66, 0.61, 0.48, 1.0)
    paper_material.roughness = 0.92

    var ink_material: StandardMaterial3D = StandardMaterial3D.new()
    ink_material.albedo_color = Color(0.08, 0.075, 0.07, 1.0)
    ink_material.roughness = 1.0

    var paper_mesh: BoxMesh = BoxMesh.new()
    paper_mesh.size = Vector3(0.46, 0.035, 0.34)
    var paper: MeshInstance3D = MeshInstance3D.new()
    paper.mesh = paper_mesh
    paper.material_override = paper_material
    paper.position = Vector3(0.0, 0.055, 0.0)
    paper.rotation.y = 0.18
    add_child(paper)

    var stripe_mesh: BoxMesh = BoxMesh.new()
    stripe_mesh.size = Vector3(0.30, 0.008, 0.025)
    for index: int in range(3):
        var stripe: MeshInstance3D = MeshInstance3D.new()
        stripe.mesh = stripe_mesh
        stripe.material_override = ink_material
        stripe.position = Vector3(0.0, 0.078, -0.075 + float(index) * 0.075)
        stripe.rotation.y = 0.18
        add_child(stripe)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.58, 0.22, 0.46)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.11, 0.0)
    add_child(collision)
