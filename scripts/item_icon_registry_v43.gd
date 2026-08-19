extends Node

const ATLAS_SIZE: Vector2i = Vector2i(448, 336)
const CELL_SIZE: Vector2i = Vector2i(56, 48)
const ATLAS_PARTS: Array[String] = [
    "res://assets/ui/items/item_icons_v43.part00",
    "res://assets/ui/items/item_icons_v43.part01",
    "res://assets/ui/items/item_icons_v43.part02",
    "res://assets/ui/items/item_icons_v43.part03",
    "res://assets/ui/items/item_icons_v43.part04",
    "res://assets/ui/items/item_icons_v43.part05",
    "res://assets/ui/items/item_icons_v43.part06",
    "res://assets/ui/items/item_icons_v43.part07"
]

const ICON_CELLS: Dictionary = {
    "flashlight": Vector2i(0, 0),
    "flashlight_battery": Vector2i(1, 0),
    "bottled_water": Vector2i(2, 0),
    "dirty_water": Vector2i(3, 0),
    "canned_food": Vector2i(4, 0),
    "medkit": Vector2i(5, 0),
    "bandage": Vector2i(6, 0),
    "scrap": Vector2i(7, 0),
    "cloth": Vector2i(0, 1),
    "wood": Vector2i(1, 1),
    "firewood_bundle": Vector2i(2, 1),
    "plastic_sheet": Vector2i(3, 1),
    "rubber": Vector2i(4, 1),
    "electronics": Vector2i(5, 1),
    "lead_plate": Vector2i(6, 1),
    "copper_wire": Vector2i(7, 1),
    "filter": Vector2i(0, 2),
    "generator_fuel": Vector2i(1, 2),
    "raw_meat": Vector2i(2, 2),
    "cooked_meat": Vector2i(3, 2),
    "raw_fish": Vector2i(4, 2),
    "cooked_fish": Vector2i(5, 2),
    "hide": Vector2i(6, 2),
    "bone": Vector2i(7, 2),
    "animal_fat": Vector2i(0, 3),
    "hunting_bow": Vector2i(1, 3),
    "arrow": Vector2i(2, 3),
    "arrow_pack": Vector2i(3, 3),
    "hunting_knife": Vector2i(4, 3),
    "fishing_rod": Vector2i(5, 3),
    "raincoat": Vector2i(6, 3),
    "radiation_suit": Vector2i(7, 3),
    "backpack": Vector2i(0, 4),
    "workbench": Vector2i(1, 4),
    "stash": Vector2i(2, 4),
    "generator": Vector2i(3, 4),
    "campfire": Vector2i(4, 4),
    "anti_radiation_tower": Vector2i(5, 4),
    "radiation_warning": Vector2i(6, 4),
    "case_file": Vector2i(7, 4),
    "survey_manifest": Vector2i(0, 5),
    "radio_log": Vector2i(1, 5),
    "maintenance_map": Vector2i(2, 5),
    "facility_badge": Vector2i(3, 5),
    "protected_zone": Vector2i(4, 5),
    "geiger_counter": Vector2i(5, 5),
    "water_purifier": Vector2i(6, 5),
    "ammo_tool_pouch": Vector2i(7, 5),
    "trap_snare": Vector2i(0, 6),
    "unknown_item": Vector2i(7, 6)
}

const ALIASES: Dictionary = {
    "clean_water": "bottled_water",
    "water": "bottled_water",
    "battery": "flashlight_battery",
    "fuel_can": "generator_fuel",
    "industrial_filter": "filter",
    "animal_hide": "hide",
    "stash_crate": "stash",
    "storage": "stash",
    "case_board": "case_file",
    "radiation_tower": "anti_radiation_tower",
    "radiation_tower_kit": "anti_radiation_tower",
    "facility_access_badge": "facility_badge"
}

var atlas_texture: ImageTexture = null
var icon_cache: Dictionary = {}
var missing_once: Dictionary = {}
var load_attempted: bool = false
var load_ok: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _load_atlas_once()

func is_ready() -> bool:
    return load_ok and atlas_texture != null

func get_icon(item_id: String) -> Texture2D:
    _load_atlas_once()
    if atlas_texture == null:
        return null

    var canonical: String = _canonical(item_id)
    if icon_cache.has(canonical):
        return icon_cache[canonical] as Texture2D

    var cell: Vector2i = Vector2i(-1, -1)
    if ICON_CELLS.has(canonical):
        cell = ICON_CELLS[canonical]
    else:
        cell = ICON_CELLS["unknown_item"]
        if not missing_once.has(canonical):
            missing_once[canonical] = true
            print("ItemIconRegistry v0.43: using fallback icon for item_id=", canonical)

    var texture: AtlasTexture = AtlasTexture.new()
    texture.atlas = atlas_texture
    texture.region = Rect2(
        float(cell.x * CELL_SIZE.x),
        float(cell.y * CELL_SIZE.y),
        float(CELL_SIZE.x),
        float(CELL_SIZE.y)
    )
    icon_cache[canonical] = texture
    return texture

func has_icon(item_id: String) -> bool:
    return ICON_CELLS.has(_canonical(item_id))

func get_recipe_icon(recipe_id: String) -> Texture2D:
    return get_icon(recipe_id)

func get_special_icon(icon_id: String) -> Texture2D:
    return get_icon(icon_id)

func _canonical(item_id: String) -> String:
    var key: String = item_id.strip_edges().to_lower()
    return str(ALIASES.get(key, key))

func _load_atlas_once() -> void:
    if load_attempted:
        return
    load_attempted = true

    var png_bytes: PackedByteArray = PackedByteArray()
    for part_path: String in ATLAS_PARTS:
        if not FileAccess.file_exists(part_path):
            push_error("ItemIconRegistry v0.43: missing atlas part: %s" % part_path)
            return
        var part_bytes: PackedByteArray = FileAccess.get_file_as_bytes(part_path)
        if part_bytes.is_empty():
            push_error("ItemIconRegistry v0.43: empty atlas part: %s" % part_path)
            return
        png_bytes.append_array(part_bytes)

    var image: Image = Image.new()
    var error: Error = image.load_png_from_buffer(png_bytes)
    if error != OK:
        push_error("ItemIconRegistry v0.43: PNG decode failed once: %s" % error_string(error))
        return

    if image.get_width() != ATLAS_SIZE.x or image.get_height() != ATLAS_SIZE.y:
        push_warning("ItemIconRegistry v0.43: atlas size %dx%d expected %dx%d" % [image.get_width(), image.get_height(), ATLAS_SIZE.x, ATLAS_SIZE.y])

    atlas_texture = ImageTexture.create_from_image(image)
    load_ok = atlas_texture != null
    if load_ok:
        print("ItemIconRegistry v0.43: atlas ready, %d mapped icons" % ICON_CELLS.size())
