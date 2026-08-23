extends Node

const ATLAS_SIZE_V73: Vector2i = Vector2i(320, 256)
const CELL_SIZE_V73: Vector2i = Vector2i(64, 64)
const ATLAS_PART_COUNT_V73: int = 7
const TALENT_ICON_CELLS_V73: Dictionary = {
    "efficient_metabolism": Vector2i(0, 0),
    "field_medic": Vector2i(1, 0),
    "pack_discipline": Vector2i(2, 0),
    "load_bearing": Vector2i(3, 0),
    "last_reserve": Vector2i(4, 0),
    "runner": Vector2i(0, 1),
    "quiet_steps": Vector2i(1, 1),
    "pathfinder": Vector2i(2, 1),
    "escape_instinct": Vector2i(3, 1),
    "ghost_trail": Vector2i(4, 1),
    "quick_repair": Vector2i(0, 2),
    "fuel_economy": Vector2i(1, 2),
    "salvager": Vector2i(2, 2),
    "circuit_memory": Vector2i(3, 2),
    "emergency_power": Vector2i(4, 2),
    "steady_hands": Vector2i(0, 3),
    "evidence_analyst": Vector2i(1, 3),
    "pattern_recognition": Vector2i(2, 3),
    "threat_familiarity": Vector2i(3, 3),
    "cold_reader": Vector2i(4, 3)
}

var atlas_texture_v73: ImageTexture
var talent_icons_v73: Dictionary = {}
var decode_ok_v73: bool = false
var decode_error_v73: String = ""

func _ready() -> void:
    _load_generated_atlas_v73()

func get_talent_icon_v73(talent_id: String) -> Texture2D:
    return talent_icons_v73.get(talent_id, null) as Texture2D

func has_talent_icon_v73(talent_id: String) -> bool:
    return talent_icons_v73.has(talent_id) and talent_icons_v73[talent_id] != null

func get_talent_icon_ids_v73() -> Array[String]:
    var ids: Array[String] = []
    for key: Variant in TALENT_ICON_CELLS_V73.keys():
        ids.append(str(key))
    return ids

func get_talent_icon_cell_v73(talent_id: String) -> Vector2i:
    var value: Variant = TALENT_ICON_CELLS_V73.get(talent_id, Vector2i(-1, -1))
    if value is Vector2i:
        return value
    return Vector2i(-1, -1)

func get_atlas_size_v73() -> Vector2i:
    if atlas_texture_v73 == null:
        return Vector2i.ZERO
    return Vector2i(atlas_texture_v73.get_size())

func is_ready_v73() -> bool:
    return decode_ok_v73 and atlas_texture_v73 != null and talent_icons_v73.size() == TALENT_ICON_CELLS_V73.size()

func get_talent_icon_contract_v73() -> Dictionary:
    return {
        "generated_icon_atlas_integrated": is_ready_v73(),
        "icon_count": talent_icons_v73.size(),
        "expected_icon_count": TALENT_ICON_CELLS_V73.size(),
        "atlas_size": get_atlas_size_v73(),
        "expected_atlas_size": ATLAS_SIZE_V73,
        "cell_size": CELL_SIZE_V73,
        "embedded_base64_parts": ATLAS_PART_COUNT_V73,
        "requires_external_png": false,
        "decode_ok": decode_ok_v73,
        "decode_error": decode_error_v73
    }

func _load_generated_atlas_v73() -> void:
    talent_icons_v73.clear()
    decode_ok_v73 = false
    decode_error_v73 = ""

    var encoded: String = ""
    for index: int in range(ATLAS_PART_COUNT_V73):
        var path: String = "res://assets/ui/talent_icons_v73.part%d" % index
        if not FileAccess.file_exists(path):
            decode_error_v73 = "Missing atlas part: %s" % path
            push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
            return
        encoded += FileAccess.get_file_as_string(path).strip_edges()

    var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
    if raw.is_empty():
        decode_error_v73 = "Base64 atlas decoded to zero bytes"
        push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
        return

    var image: Image = Image.new()
    var load_error: Error = image.load_png_from_buffer(raw)
    if load_error != OK:
        decode_error_v73 = "PNG decode failed with error %d" % int(load_error)
        push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
        return
    if image.get_size() != ATLAS_SIZE_V73:
        decode_error_v73 = "Unexpected atlas size %s" % str(image.get_size())
        push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
        return

    atlas_texture_v73 = ImageTexture.create_from_image(image)
    if atlas_texture_v73 == null:
        decode_error_v73 = "ImageTexture creation failed"
        push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
        return

    for talent_value: Variant in TALENT_ICON_CELLS_V73.keys():
        var talent_id: String = str(talent_value)
        var cell: Vector2i = get_talent_icon_cell_v73(talent_id)
        var icon: AtlasTexture = AtlasTexture.new()
        icon.atlas = atlas_texture_v73
        icon.region = Rect2(
            Vector2(cell.x * CELL_SIZE_V73.x, cell.y * CELL_SIZE_V73.y),
            Vector2(CELL_SIZE_V73)
        )
        talent_icons_v73[talent_id] = icon

    decode_ok_v73 = talent_icons_v73.size() == 20
    if decode_ok_v73:
        print("TalentIconRegistry v0.73: generated 20-icon talent atlas ready")
    else:
        decode_error_v73 = "Icon region build incomplete"
        push_error("TalentIconRegistry v0.73: %s" % decode_error_v73)
