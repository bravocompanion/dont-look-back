extends "res://scripts/survival_system.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"

## The base SurvivalSystem predates the ranger-first flow and used to inject
## Apartment/Labyrinth pickups into every gameplay scene. Keep that legacy
## setup strictly inside the Labyrinth; Forest/Mine/Facility own their content.
func _configure_scene(scene: Node) -> void:
    if scene == null or not is_instance_valid(scene):
        return
    if scene.scene_file_path != LABYRINTH_SCENE_PATH:
        return
    await super._configure_scene(scene)
