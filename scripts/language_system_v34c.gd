extends "res://scripts/language_system_v34b.gd"

const FINAL_EXACT_EN_TO_ID: Dictionary = {
    "RANGER CASE 07 — Survive the forest, investigate the missing survey team, then follow the evidence underground.": "KASUS RANGER 07 — Bertahan di hutan, selidiki tim survey yang hilang, lalu ikuti bukti ke bawah tanah.",
    "Preparing the ranger station in the forest...": "Menyiapkan ranger station di hutan...",
    "Connected. Preparing the ranger investigation...": "Terhubung. Menyiapkan investigasi ranger...",
    "NEW GAME: Ranger Forest → evidence → Old Mine → Labyrinth → Research Facility.": "GAME BARU: Hutan Ranger → bukti → Tambang Tua → Labyrinth → Fasilitas Riset.",
    "The game starts in Ranger Forest. Progress follows Forest → Mine → Labyrinth → Research Facility.": "Game dimulai di Hutan Ranger. Progress mengikuti Hutan → Tambang → Labyrinth → Fasilitas Riset.",
    "Start as a ranger at the forest cabin. Survive first, then follow the evidence.": "Mulai sebagai ranger di cabin hutan. Bertahan dulu, lalu ikuti bukti.",
    "Host co-op starts in the same Ranger Forest.": "Host co-op dimulai di Hutan Ranger yang sama.",
    "Join the host and synchronize to the host's investigation scene.": "Gabung ke host dan sinkron ke scene investigasi host.",
    "RANGER DEPLOYMENT: Cabin behind you. Face the forest, secure the shelter, then begin the investigation.": "DEPLOYMENT RANGER: Cabin ada di belakangmu. Hadapi hutan, amankan base, lalu mulai investigasi.",
    "RANGER BASE: Secure food, water, fuel, and light before night.": "BASE RANGER: Amankan makanan, air, bahan bakar, dan cahaya sebelum malam.",
    "CASE 07 • Missing survey team • Research begins after the base is stable": "KASUS 07 • Tim survey hilang • Investigasi dimulai setelah base stabil",
    "Survive first. Then follow the evidence.": "Bertahan dulu. Lalu ikuti bukti.",
    "A ranger who cannot survive cannot finish the investigation.": "Ranger yang tidak dapat bertahan tidak dapat menyelesaikan investigasi.",
    "MINE INVESTIGATION: Find evidence and the sealed facility access.": "INVESTIGASI TAMBANG: Temukan bukti dan akses fasilitas yang disegel.",
    "CASE 07 • Shaft 03 • Separate scene from Forest and Labyrinth": "KASUS 07 • Shaft 03 • Scene terpisah dari Hutan dan Labyrinth",
    "RESTRICTED FACILITY: Inspect the routing terminal.": "FASILITAS TERBATAS: Periksa terminal routing.",
    "CASE 07 • T-03 network • Next expedition targets": "KASUS 07 • Jaringan T-03 • Target ekspedisi berikutnya",
    "Preparing ranger station in forest...": "Menyiapkan ranger station di hutan...",
    "Connected. Preparing ranger investigation...": "Terhubung. Menyiapkan investigasi ranger..."
}

const FINAL_ID_TO_EN: Dictionary = {
    "Menyiapkan ranger station di forest...": "Preparing the ranger station in the forest...",
    "Menyiapkan ranger station di hutan...": "Preparing the ranger station in the forest...",
    "Terhubung. Menyiapkan ranger investigation...": "Connected. Preparing the ranger investigation...",
    "Terhubung. Menyiapkan investigasi ranger...": "Connected. Preparing the ranger investigation...",
    "Game dimulai di Ranger Forest. Progress mengikuti Forest → Mine → Labyrinth → Research Facility.": "The game starts in Ranger Forest. Progress follows Forest → Mine → Labyrinth → Research Facility.",
    "Game dimulai di Hutan Ranger. Progress mengikuti Hutan → Tambang → Labyrinth → Fasilitas Riset.": "The game starts in Ranger Forest. Progress follows Forest → Mine → Labyrinth → Research Facility.",
    "Mulai sebagai ranger di cabin forest. Survival dulu, lalu ikuti evidence.": "Start as a ranger at the forest cabin. Survive first, then follow the evidence.",
    "Mulai sebagai ranger di cabin hutan. Bertahan dulu, lalu ikuti bukti.": "Start as a ranger at the forest cabin. Survive first, then follow the evidence.",
    "Host co-op dimulai di Ranger Forest yang sama.": "Host co-op starts in the same Ranger Forest.",
    "Host co-op dimulai di Hutan Ranger yang sama.": "Host co-op starts in the same Ranger Forest.",
    "Join host dan sinkron ke scene investigasi host.": "Join the host and synchronize to the host's investigation scene.",
    "Gabung ke host dan sinkron ke scene investigasi host.": "Join the host and synchronize to the host's investigation scene.",
    "RANGER DEPLOYMENT: Cabin di belakangmu. Hadapi hutan, amankan shelter, lalu mulai investigasi.": "RANGER DEPLOYMENT: Cabin behind you. Face the forest, secure the shelter, then begin the investigation.",
    "DEPLOYMENT RANGER: Cabin ada di belakangmu. Hadapi hutan, amankan base, lalu mulai investigasi.": "RANGER DEPLOYMENT: Cabin behind you. Face the forest, secure the shelter, then begin the investigation."
}

var final_reverse: Dictionary = {}

func _ready() -> void:
    super._ready()
    final_reverse.clear()
    for english_variant: Variant in FINAL_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        final_reverse[str(FINAL_EXACT_EN_TO_ID[english_variant])] = english_text
    for id_variant: Variant in FINAL_ID_TO_EN.keys():
        final_reverse[str(id_variant)] = str(FINAL_ID_TO_EN[id_variant])

func _canonicalize_text(text: String) -> String:
    var result: String = str(final_reverse.get(text, text))
    result = super._canonicalize_text(result)
    if final_reverse.has(result):
        result = str(final_reverse[result])
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    if FINAL_EXACT_EN_TO_ID.has(text):
        return str(FINAL_EXACT_EN_TO_ID[text])
    var result: String = super._translate_gameplay_to_indonesian(text)
    for english_variant: Variant in FINAL_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        result = result.replace(english_text, str(FINAL_EXACT_EN_TO_ID[english_variant]))
    return result

func _localize_status(text: String) -> String:
    var canonical: String = str(final_reverse.get(text, text))
    if language_code == "en" and FINAL_ID_TO_EN.has(text):
        return str(FINAL_ID_TO_EN[text])
    if language_code == "id" and FINAL_EXACT_EN_TO_ID.has(canonical):
        return str(FINAL_EXACT_EN_TO_ID[canonical])
    return super._localize_status(canonical)

func _localize_control(node: Node) -> void:
    super._localize_control(node)
    if node is Control:
        var control: Control = node as Control
        if not control.tooltip_text.is_empty():
            control.tooltip_text = localize_gameplay_text(str(final_reverse.get(control.tooltip_text, control.tooltip_text)))
