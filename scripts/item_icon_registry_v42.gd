extends Node

const IconData00 = preload("res://scripts/icon_data/item_icon_data_00.gd")
const IconData01 = preload("res://scripts/icon_data/item_icon_data_01.gd")
const IconData02 = preload("res://scripts/icon_data/item_icon_data_02.gd")
const IconData03 = preload("res://scripts/icon_data/item_icon_data_03.gd")
const IconData04 = preload("res://scripts/icon_data/item_icon_data_04.gd")
const IconData05 = preload("res://scripts/icon_data/item_icon_data_05.gd")
const IconData06 = preload("res://scripts/icon_data/item_icon_data_06.gd")
const IconData07 = preload("res://scripts/icon_data/item_icon_data_07.gd")
const IconData08 = preload("res://scripts/icon_data/item_icon_data_08.gd")
const IconData09 = preload("res://scripts/icon_data/item_icon_data_09.gd")
const IconData10 = preload("res://scripts/icon_data/item_icon_data_10.gd")
const IconData11 = preload("res://scripts/icon_data/item_icon_data_11.gd")

const ATLAS_SIZE: Vector2i = Vector2i(896, 672)
const CELL_SIZE: Vector2i = Vector2i(112, 96)

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

    "trap_snare": Vector2i(0, 6)
}

const ALIASES: Dictionary = {
    "clean_water": "bottled_water",
    "water": "bottled_water",
    "fuel_can": "generator_fuel",
    "battery": "flashlight_battery",
    "industrial_filter": "filter",
    "animal_hide": "hide",
    "stash_crate": "stash",
    "storage": "stash",
    "case_board": "case_file",
    "radiation_tower": "anti_radiation_tower"
}

var atlas_texture: ImageTexture = null
var icon_cache: Dictionary = {}

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _ensure_atlas()

func get_icon(item_id: String) -> Texture2D:
    _ensure_atlas()
    if atlas_texture == null:
        return null

    var canonical: String = _canonical(item_id)
    if icon_cache.has(canonical):
        return icon_cache[canonical] as Texture2D
    if not ICON_CELLS.has(canonical):
        return null

    var cell: Vector2i = ICON_CELLS[canonical]
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
    match recipe_id:
        "firewood_bundle": return get_icon("firewood_bundle")
        "flashlight_battery": return get_icon("flashlight_battery")
        "bandage": return get_icon("bandage")
        "raincoat": return get_icon("raincoat")
        "radiation_suit": return get_icon("radiation_suit")
        "hunting_bow": return get_icon("hunting_bow")
        "arrow_pack": return get_icon("arrow_pack")
        "hunting_knife": return get_icon("hunting_knife")
        "anti_radiation_tower": return get_icon("anti_radiation_tower")
    return get_icon(recipe_id)

func get_special_icon(icon_id: String) -> Texture2D:
    return get_icon(icon_id)

func _canonical(item_id: String) -> String:
    var key: String = item_id.strip_edges().to_lower()
    return str(ALIASES.get(key, key))

func _ensure_atlas() -> void:
    if atlas_texture != null:
        return

    var encoded: String = (
        IconData00.DATA + IconData01.DATA + IconData02.DATA + IconData03.DATA
        + IconData04.DATA + IconData05.DATA + IconData06.DATA + IconData07.DATA
        + IconData08.DATA + IconData09.DATA + IconData10.DATA + IconData11.DATA
    )
    var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
    if raw.is_empty():
        push_error("ItemIconRegistry: embedded atlas data is empty.")
        return

    var image: Image = Image.new()
    var error: Error = image.load_png_from_buffer(raw)
    if error != OK:
        push_error("ItemIconRegistry: PNG atlas decode failed (%s)." % error_string(error))
        return

    atlas_texture = ImageTexture.create_from_image(image)
