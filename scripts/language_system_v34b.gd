extends "res://scripts/language_system_v34.gd"

const RUNTIME_UI_EN_TO_ID: Dictionary = {
    "HUNT": "BURU",
    "READY": "SIAP",
    "NOT READY": "BELUM SIAP",
    "START": "MULAI",
    "LEAVE": "KELUAR",
    "RECONNECT": "SAMBUNG LAGI",
    "DOWNED": "TUMBANG",
    "USE TO REVIVE": "GUNAKAN UNTUK MEMBANGKITKAN",
    "YOU ARE DOWNED": "KAMU TUMBANG",
    "BLEEDING": "PENDARAHAN",
    "BLEED": "DARAH",
    "INFECTION": "INFEKSI",
    "INF": "INF",
    "WEATHER": "CUACA",
    "WET": "BASAH",
    "CLEAR": "CERAH",
    "CLOUDY": "BERAWAN",
    "RAIN": "HUJAN",
    "STORM": "BADAI"
}

const RUNTIME_EXACT_EN_TO_ID: Dictionary = {
    "You're bleeding. Use a Bandage or Medkit before the wound gets infected.": "Kamu mengalami pendarahan. Gunakan Perban atau Medkit sebelum luka terinfeksi.",
    "You drink clean water.": "Kamu meminum air bersih.",
    "You drink untreated water. Thirst drops, but Infection rises.": "Kamu meminum air tanpa pengolahan. Haus berkurang, tetapi Infeksi meningkat.",
    "You bind the wound with a Bandage.": "Kamu membalut luka dengan Perban.",
    "You clean and dress your wounds with the Medkit.": "Kamu membersihkan dan merawat luka dengan Medkit.",
    "You need a Bandage or Medkit to stop the bleeding.": "Kamu membutuhkan Perban atau Medkit untuk menghentikan pendarahan.",
    "You need a Medkit to treat the infection.": "Kamu membutuhkan Medkit untuk mengobati infeksi.",
    "You do not need medical aid right now.": "Kamu belum membutuhkan bantuan medis saat ini.",
    "You have no medical supplies.": "Kamu tidak punya persediaan medis.",
    "The boiling pot needs the shelter campfire.": "Panci perebus membutuhkan api unggun base.",
    "Light the campfire before boiling water.": "Nyalakan api unggun sebelum merebus air.",
    "You have no Dirty Water to boil.": "Kamu tidak punya Air Kotor untuk direbus.",
    "Inventory full. The Dirty Water was not processed.": "Inventaris penuh. Air Kotor tidak diproses.",
    "You boil the Dirty Water into safe Clean Water.": "Kamu merebus Air Kotor menjadi Air Bersih yang aman.",
    "Clean Water": "Air Bersih",
    "You need the Fishing Rod from the ranger cache before fishing.": "Kamu membutuhkan Pancing dari cache ranger sebelum memancing.",
    "You need the Hunting Bow from the ranger cache.": "Kamu membutuhkan Busur Berburu dari cache ranger.",
    "No arrows left. Search containers or return to the ranger cache on a fresh run.": "Panah habis. Cari container atau kembali ke cache ranger pada run baru.",
    "The arrow vanishes between the trees.": "Panah menghilang di antara pepohonan.",
    "The arrow strikes something that is not prey.": "Panah mengenai sesuatu yang bukan hewan buruan.",
    "You wait, feel one pull on the line, then nothing. The fish got away.": "Kamu menunggu, merasakan satu tarikan pada tali, lalu tidak ada apa-apa. Ikannya lepas.",
    "Something is forming in the dark. GET TO THE LIGHT.": "Sesuatu sedang terbentuk dalam kegelapan. SEGERA KE CAHAYA.",
    "A survivor must reach you and revive you.\nStay together. Light protects the team.": "Seorang survivor harus mencapai dan membangkitkanmu.\nTetap bersama. Cahaya melindungi tim.",
    "Need at least 2 survivors before START.": "Butuh setidaknya 2 survivor sebelum MULAI.",
    "Every connected survivor must be READY.": "Semua survivor yang terhubung harus SIAP.",
    "Player not ready yet.": "Player belum siap.",
    "Team ready. Stay together and keep the light moving.": "Tim siap. Tetap bersama dan jaga cahaya terus bergerak.",
    "DOWNED\nUSE TO REVIVE": "TUMBANG\nGUNAKAN UNTUK MEMBANGKITKAN",
    "YOU ARE DOWNED": "KAMU TUMBANG",
    "The water needs time to settle.": "Air membutuhkan waktu untuk kembali tenang.",
    "The fish got away.": "Ikannya lepas.",
    "Wild Boar": "Babi Hutan Liar",
    "Wolf": "Serigala",
    "the darkness": "kegelapan",
    "bleeding": "pendarahan",
    "infection": "infeksi",
    "starvation": "kelaparan",
    "dehydration": "dehidrasi",
    "exposure": "paparan"
}

const RUNTIME_PHRASE_EN_TO_ID: Array[PackedStringArray] = [
    PackedStringArray(["WEATHER ", "CUACA "]),
    PackedStringArray(["CLEAR", "CERAH"]),
    PackedStringArray(["CLOUDY", "BERAWAN"]),
    PackedStringArray(["RAIN", "HUJAN"]),
    PackedStringArray(["STORM", "BADAI"]),
    PackedStringArray(["WET ", "BASAH "]),
    PackedStringArray(["BLEEDING ", "PENDARAHAN "]),
    PackedStringArray(["BLEED ", "DARAH "]),
    PackedStringArray(["INFECTION ", "INFEKSI "]),
    PackedStringArray(["The water needs time to settle. Try fishing again in ", "Air membutuhkan waktu untuk kembali tenang. Coba memancing lagi dalam "]),
    PackedStringArray([" seconds.", " detik."]),
    PackedStringArray(["FISHING: caught ", "MEMANCING: mendapat "]),
    PackedStringArray([" freshwater fish. Cook it before eating.", " ikan air tawar. Masak sebelum dimakan."]),
    PackedStringArray(["HUNT: ", "BURU: "]),
    PackedStringArray([" is down. Follow the blood trail and harvest the carcass with the Hunting Knife before leaving it.", " tumbang. Ikuti jejak darah dan panen bangkai dengan Pisau Berburu sebelum meninggalkannya."]),
    PackedStringArray(["Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.", "Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide."]),
    PackedStringArray(["You need the Hunting Knife to harvest the carcass without damaging the meat and hide.", "Kamu membutuhkan Pisau Berburu untuk memanen bangkai tanpa merusak daging dan kulit."]),
    PackedStringArray(["That carcass can no longer be harvested.", "Bangkai itu sudah tidak dapat dipanen."]),
    PackedStringArray(["That carcass was already harvested by another teammate.", "Bangkai itu sudah dipanen anggota tim lain."]),
    PackedStringArray(["HARVEST: ", "PANEN: "]),
    PackedStringArray([" harvested — ", " dipanen — "]),
    PackedStringArray([". Raw food must be cooked at the campfire.", ". Makanan mentah harus dimasak di api unggun."]),
    PackedStringArray(["Revive Survivor ", "Bangkitkan Survivor "]),
    PackedStringArray(["Revive ", "Bangkitkan "]),
    PackedStringArray(["GENERATOR ", "GENERATOR "]),
    PackedStringArray(["CAMPFIRE ", "API UNGGUN "]),
    PackedStringArray(["STORAGE ", "PENYIMPANAN "]),
    PackedStringArray(["SHELTER  |  ", "BASE  |  "]),
    PackedStringArray(["BOX ", "BOX "])
]

var runtime_reverse_ui: Dictionary = {}
var runtime_reverse_exact: Dictionary = {}

func _ready() -> void:
    super._ready()
    _build_runtime_reverse_maps()

func _build_runtime_reverse_maps() -> void:
    runtime_reverse_ui.clear()
    for english_variant: Variant in RUNTIME_UI_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        runtime_reverse_ui[str(RUNTIME_UI_EN_TO_ID[english_variant])] = english_text
    runtime_reverse_exact.clear()
    for english_variant: Variant in RUNTIME_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        runtime_reverse_exact[str(RUNTIME_EXACT_EN_TO_ID[english_variant])] = english_text

func _apply_localization() -> void:
    super._apply_localization()
    _localize_runtime_survival_ui()
    _localize_runtime_multiplayer_ui()
    _localize_condition_status()

func _localize_ui_exact(text: String) -> String:
    var canonical: String = str(runtime_reverse_ui.get(text, runtime_reverse_exact.get(text, text)))
    var parent_result: String = super._localize_ui_exact(canonical)
    if language_code == "id":
        if RUNTIME_UI_EN_TO_ID.has(canonical):
            return str(RUNTIME_UI_EN_TO_ID[canonical])
        if RUNTIME_EXACT_EN_TO_ID.has(canonical):
            return str(RUNTIME_EXACT_EN_TO_ID[canonical])
    if language_code == "en":
        return str(runtime_reverse_ui.get(parent_result, runtime_reverse_exact.get(parent_result, parent_result)))
    return parent_result

func _canonicalize_text(text: String) -> String:
    var result: String = super._canonicalize_text(text)
    if runtime_reverse_exact.has(result):
        result = str(runtime_reverse_exact[result])
    for pair: PackedStringArray in RUNTIME_PHRASE_EN_TO_ID:
        if pair[0] == pair[1]:
            continue
        result = result.replace(pair[1], pair[0])
    for id_variant: Variant in runtime_reverse_ui.keys():
        var id_text: String = str(id_variant)
        result = result.replace(id_text, str(runtime_reverse_ui[id_variant]))
    # Canonicalize hard-coded Indonesian hunting messages from v0.26.
    result = result.replace("Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.", "You need the Hunting Knife to harvest the carcass without damaging the meat and hide.")
    result = result.replace("Carcass itu sudah tidak dapat dipanen.", "That carcass can no longer be harvested.")
    result = result.replace("Carcass itu sudah dipanen anggota tim lain.", "That carcass was already harvested by another teammate.")
    result = result.replace(" tumbang. Ikuti jejak darah dan panen carcass dengan Hunting Knife sebelum meninggalkannya.", " is down. Follow the blood trail and harvest the carcass with the Hunting Knife before leaving it.")
    result = result.replace(" dipanen — ", " harvested — ")
    result = result.replace(". Raw food harus dimasak di campfire.", ". Raw food must be cooked at the campfire.")
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    if RUNTIME_EXACT_EN_TO_ID.has(text):
        return str(RUNTIME_EXACT_EN_TO_ID[text])
    var result: String = super._translate_gameplay_to_indonesian(text)
    for pair: PackedStringArray in RUNTIME_PHRASE_EN_TO_ID:
        if pair[0] == pair[1]:
            continue
        result = result.replace(pair[0], pair[1])
    for english_variant: Variant in RUNTIME_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        result = result.replace(english_text, str(RUNTIME_EXACT_EN_TO_ID[english_variant]))
    return result

func _localize_runtime_survival_ui() -> void:
    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null:
        _localize_property_tree(forest_runtime, "ui_layer")
        var weather_value: Variant = _safe_property(forest_runtime, "weather_label")
        if weather_value is Label:
            var weather: Label = weather_value as Label
            weather.text = localize_gameplay_text(weather.text)
        var hunt_value: Variant = _safe_property(forest_runtime, "hunt_button")
        if hunt_value is Button:
            var hunt: Button = hunt_value as Button
            hunt.text = _localize_ui_exact(hunt.text)

func _localize_runtime_multiplayer_ui() -> void:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop != null:
        _localize_property_tree(coop, "downed_layer")
        for property_name: String in ["downed_title", "downed_help"]:
            var value: Variant = _safe_property(coop, property_name)
            if value is Label:
                var label: Label = value as Label
                label.text = localize_gameplay_text(label.text)

    var polish: Node = get_node_or_null("/root/MultiplayerPolishSystem")
    if polish != null:
        _localize_property_tree(polish, "layer")
        for property_name: String in ["teammate_label", "mission_label", "connection_label", "roster_label", "revive_label"]:
            var value: Variant = _safe_property(polish, property_name)
            if value is Label:
                var label: Label = value as Label
                label.text = localize_gameplay_text(label.text)

func _localize_condition_status() -> void:
    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth == null:
        return
    var value: Variant = _safe_property(depth, "status_label")
    if not (value is Label):
        return
    var status: Label = value as Label
    status.text = localize_gameplay_text(status.text)

func _localize_property_tree(owner: Node, property_name: String) -> void:
    var value: Variant = _safe_property(owner, property_name)
    if value is Node:
        _localize_runtime_tree(value as Node)

func _localize_runtime_tree(node: Node) -> void:
    if node == null:
        return
    if node is Button:
        var button: Button = node as Button
        if button.name != "LanguageToggle":
            button.text = _localize_ui_exact(button.text)
            if not button.tooltip_text.is_empty():
                button.tooltip_text = localize_gameplay_text(button.tooltip_text)
    elif node is Label:
        var label: Label = node as Label
        label.text = localize_gameplay_text(_localize_ui_exact(label.text))
    elif node is RichTextLabel:
        var rich: RichTextLabel = node as RichTextLabel
        rich.text = localize_gameplay_text(rich.text)
    elif node is LineEdit:
        var line_edit: LineEdit = node as LineEdit
        line_edit.placeholder_text = _localize_ui_exact(line_edit.placeholder_text)
    for child: Node in node.get_children():
        _localize_runtime_tree(child)

func _safe_property(owner: Object, property_name: String) -> Variant:
    if owner == null:
        return null
    for info_variant: Variant in owner.get_property_list():
        var info: Dictionary = Dictionary(info_variant)
        if str(info.get("name", "")) == property_name:
            return owner.get(property_name)
    return null
