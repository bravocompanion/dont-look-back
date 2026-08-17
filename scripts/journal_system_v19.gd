extends "res://scripts/journal_system.gd"

func _ready() -> void:
    super._ready()
    _add_entry(
        "world_premise",
        "Kenapa Kamu Harus Keluar",
        "LORE",
        "Labyrinth bukan pusat dunia yang sudah rusak. Ia hanya salah satu simpul pertama dari sesuatu yang jauh lebih besar. Fasilitas bawah tanah pernah mempelajari fenomena ruang gelap yang diberi kode SUBJEK T-03. Para teknisi menyebut manifestasinya The Tenant. Setelah insiden 03:13, catatan terakhir menyebut fenomena serupa muncul di rumah sakit, museum, laboratorium terpencil, sistem gua, dan permukiman di luar fasilitas. Jika catatan itu benar, manusia belum kalah—tetapi jawabannya tersebar di banyak tempat. Tujuanmu bukan sekadar keluar hidup-hidup. Kamu harus menemukan apa yang terjadi, mengumpulkan jurnal dan data para penyintas, lalu menyusun cara agar manusia bisa hidup kembali tanpa terus bersembunyi dari kegelapan."
    )
    _add_entry(
        "humanity_mission",
        "Misi Jangka Panjang",
        "PRIMARY MISSION",
        "FASE 1 — ESCAPE: keluar dari Labyrinth sambil memahami aturan ancaman.\n\nFASE 2 — SURVIVE: bangun ritme hidup di hutan. Cari air, makanan, bahan bakar, tempat berlindung, obat, dan sumber cahaya.\n\nFASE 3 — ADAPT: berburu, memancing, memasak, mengolah air, menghadapi cuaca, penyakit, luka, hewan liar, dan monster.\n\nFASE 4 — EXPLORE: gunakan shelter sebagai base lalu lakukan ekspedisi ke lokasi berbahaya.\n\nFASE 5 — INVESTIGATE: cari jurnal, rekaman, sampel, artefak, peta, dan data dari Rumah Sakit, Museum, Laboratorium, Gua, serta Labyrinth lain.\n\nFASE 6 — SAVE HUMANITY: hubungkan semua bukti untuk menemukan sumber fenomena dan metode melawan atau menghentikannya. Ending tidak dicapai karena pemain menemukan satu pintu keluar, tetapi karena pemain akhirnya memahami apa yang harus dilakukan umat manusia untuk bertahan."
    )
    _add_entry(
        "creature_rules",
        "Aturan yang Ditinggalkan Penyintas",
        "SURVIVAL",
        "1. The Tenant bergerak saat perhatianmu lepas. Melihatnya memberi waktu; cahaya memberi ruang.\n\n2. Darkness bukan sekadar kurang cahaya. Exposure yang lama membuat makhluk gelap dapat mendekat dan menyerang.\n\n3. Mourner mengikuti suara. Sprint dan interaksi keras bisa menyelamatkan beberapa detik sekaligus memberitahu posisimu.\n\n4. Crawler menghukum stamina kosong dan koridor sempit.\n\n5. Luka tidak selesai setelah serangan. Bleeding dan Infection bisa membunuh jauh setelah monster pergi.\n\n6. Hutan punya ancamannya sendiri: kelaparan, dehidrasi, suhu, cuaca, penyakit, hewan liar, malam, dan jarak dari shelter.\n\n7. Tidak semua perjalanan harus dilakukan. Kadang keputusan paling penting adalah pulang sebelum malam."
    )
    _add_entry(
        "route_overview",
        "Rute Utama — Dari Terjebak Menjadi Penyelamat",
        "MISSION GUIDE",
        "BAB I — Apartment 03: cari perlengkapan dan petunjuk pertama.\n\nBAB II — Lower Labyrinth: hidupkan emergency relay dan temukan bukti bahwa fasilitas ini bukan satu-satunya lokasi insiden.\n\nARC 1 — Maintenance / Flooded Service / Archive / Lockdown: pulihkan sistem, ambil data T-03, dan buka jalan keluar.\n\nBAB III — Forest Survival: temukan cabin, hidupkan shelter, kuasai kebutuhan dasar, lalu jadikan hutan sebagai base operasi.\n\nFASE EKSPEDISI — temukan jalur menuju Rumah Sakit, Museum, Laboratorium, Gua, dan Labyrinth lain. Setiap lokasi memiliki journal chain dan potongan jawaban yang berbeda.\n\nENDGAME — gabungkan pengetahuan dari seluruh lokasi untuk menentukan sumber, kelemahan, dan solusi bagi fenomena yang mengancam manusia."
    )
    _add_entry(
        "expedition_targets",
        "Lokasi yang Harus Dicari",
        "EXPEDITION BOARD",
        "RUMAH SAKIT — catatan medis, mutasi pasien, generator emergency, obat dan data korban pertama.\n\nMUSEUM — artefak lama yang menunjukkan fenomena ini mungkin sudah muncul jauh sebelum fasilitas modern dibangun.\n\nLABORATORIUM — data eksperimen, sampel, protokol T-03, dan kemungkinan metode containment.\n\nGUA — sumber geologis/biologis yang tidak bisa dijelaskan oleh catatan fasilitas. Tanpa listrik, cahaya menjadi resource utama.\n\nLABYRINTH LAIN — simpul fenomena dengan aturan ruang berbeda. Bisa menyimpan perangkat atau informasi yang dibutuhkan untuk endgame.\n\nLokasi-lokasi ini bukan dungeon acak. Setiap ekspedisi harus memberi jawaban baru sekaligus membuka pertanyaan berikutnya."
    )
    _add_entry(
        "forest_survival_plan",
        "Rencana Bertahan di Permukaan",
        "SURVIVAL PLAN",
        "Hutan adalah tempat hidup sekaligus staging ground. Prioritas jangka pendek: shelter, air, makanan, api, obat, cahaya, dan bahan bakar. Prioritas menengah: hunting, fishing, cooking, water purification, storage, crafting, weather protection, dan route marking. Prioritas jangka panjang: kumpulkan suplai ekspedisi, tentukan waktu berangkat berdasarkan cuaca dan daylight, lalu kembali ke base membawa jurnal/data tanpa menghabiskan seluruh resource di perjalanan."
    )
    _update_mission()
    _update_entry_display()

func _get_current_mission() -> String:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return "STATUS: Belum ada survivor lokal.\nTUJUAN: Masuk ke permainan dan cari orientasi."

    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var outside_active: bool = outside != null and outside.has_method("is_outside_active") and bool(outside.call("is_outside_active"))
    if outside_active:
        return _outside_mission(player, outside)

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null:
        var stage: int = int(arc.get("current_stage"))
        var completed: Dictionary = Dictionary(arc.get("completed"))
        var breaker_progress: int = int(arc.get("breaker_progress"))
        var holdout_active: bool = bool(arc.get("holdout_active"))
        var holdout_remaining: float = float(arc.get("holdout_remaining"))

        if stage == 1:
            var fuse_count: int = _count_arc_ids(completed, ["fuse_a", "fuse_b", "fuse_c"])
            return "ARC 1 — MAINTENANCE WING\nTUJUAN UTAMA: Pulihkan tiga fuse box (%d / 3).\nLANGKAH: 1) Cari Fuse A/B/C. 2) Dengarkan arah Mourner sebelum sprint. 3) Gunakan pocket cahaya untuk reposisi. 4) Loot side route dan cari dokumen staf.\nRISIKO: Noise menarik Mourner; panic tinggi memperburuk pengambilan keputusan.\nALASAN MISI: Fuse memberi daya ke sektor yang menyimpan data insiden. Kamu tidak hanya membuka pintu—kamu sedang membuka akses menuju bukti yang mungkin dibutuhkan umat manusia." % fuse_count
        if stage == 2:
            var valve_count: int = _count_arc_ids(completed, ["valve_a", "valve_b"])
            return "ARC 1 — FLOODED SERVICE\nTUJUAN UTAMA: Tutup dua pressure valve (%d / 2).\nLANGKAH: 1) Cari Valve A dan B. 2) Hindari jalur gelap hanya karena lebih pendek. 3) Ambil suplai di cabang samping. 4) Sisakan stamina untuk keluar.\nRISIKO: Area sempit dan gelap memberi Crawler keuntungan.\nALASAN MISI: Tekanan air harus turun agar Archive bisa menerima daya stabil. Archive adalah tempat staf menyimpan laporan tentang penyebaran fenomena di luar fasilitas." % valve_count
        if stage == 3:
            return "ARC 1 — ARCHIVE\nTUJUAN UTAMA: Masukkan breaker B → A → C. Progress %d / 3.\nLANGKAH: 1) Temukan panel. 2) Hafalkan urutan. 3) Setelah setiap breaker, cek jalur mundur dan baterai. 4) Cari file T-03 dan daftar lokasi eksternal.\nRISIKO: Urutan salah memicu blackout alarm dan aggression musuh.\nALASAN MISI: Di sinilah tujuan permainan berubah dari 'keluar hidup-hidup' menjadi 'cari jawaban'. Data Archive menunjukkan insiden serupa terjadi di lokasi lain." % breaker_progress
        if stage == 4:
            return "ARC 1 — LOCKDOWN PREP\nTUJUAN UTAMA: Siapkan diri sebelum console terakhir.\nCHECKLIST: Heal • minum • makan • baterai cukup • Bandage/Medkit • stamina penuh • kenali minimal dua pocket cahaya.\nRISIKO: Setelah aktif, pintu terkunci dan proses tidak bisa dibatalkan dengan aman.\nALASAN MISI: Lockdown membuka jalur evakuasi dan memungkinkanmu membawa data keluar. Mati di sini berarti jawaban tetap terkubur di bawah tanah."
        if stage == 5 or holdout_active:
            var seconds: int = maxi(0, int(ceil(holdout_remaining)))
            return "ARC 1 — LOCKDOWN AKTIF\nTUJUAN UTAMA: Bertahan %d:%02d lagi.\nLANGKAH: 1) Bergerak antar pocket cahaya. 2) Jangan bertahan di sudut. 3) Gunakan stamina untuk reposisi. 4) Simpan baterai untuk transisi gelap.\nRISIKO: Alarm memanggil Mourner/Crawler dan aggression meningkat.\nALASAN MISI: Kamu tidak perlu membunuh semuanya. Kamu hanya perlu hidup cukup lama agar jalur menuju permukaan terbuka dan data bisa dibawa keluar." % [seconds / 60, seconds % 60]
        if stage >= 6:
            return "ARC 1 — EXIT TERBUKA\nTUJUAN UTAMA: Keluar dengan resource dan data sebanyak mungkin.\nLANGKAH: 1) Ambil suplai terakhir yang aman. 2) Jangan tukar health untuk loot kecil. 3) Masuk exit dengan kondisi cukup untuk bertahan di permukaan.\nBERIKUTNYA: Hutan bukan ending. Hutan adalah base survival pertama sebelum ekspedisi ke Rumah Sakit, Museum, Laboratorium, Gua, dan Labyrinth lain."

    var relay_count: int = _relay_count()
    if relay_count >= 3:
        return "LOWER LABYRINTH — GERBANG SIAP\nTUJUAN UTAMA: Ikuti beacon menuju fasilitas inti.\nLANGKAH: Isi baterai, air, makanan, dan medical supply sebelum melewati gerbang. Cari setiap tulisan yang menyebut T-03 atau lokasi di luar fasilitas.\nALASAN MISI: Tiga relay tidak hanya membuka jalan keluar. Mereka membuka bagian fasilitas yang mungkin menjelaskan kenapa dunia di luar ikut terinfeksi."

    if player.global_position.z < -15.0:
        return "BAB II — LOWER LABYRINTH\nTUJUAN UTAMA: Aktifkan 3 emergency relay (%d / 3).\nLANGKAH: 1) Cari relay/cahaya berikutnya. 2) Loot baterai dan suplai. 3) Jaga Darkness Exposure. 4) Saat Tenant muncul, jaga perhatian dan cari ruang terang. 5) Periksa memo dan journal di jalur samping.\nRISIKO: Bergerak menaikkan panic; sprint menaikkannya lebih cepat.\nALASAN MISI: Kamu mulai menemukan bukti bahwa Labyrinth ini hanyalah satu node dari kejadian yang lebih luas." % relay_count

    return "BAB I — TERJEBAK DI LABYRINTH\nTUJUAN UTAMA: Bertahan, pahami aturan tempat ini, dan cari jalan lebih dalam sebelum akhirnya menemukan jalan keluar.\nLANGKAH: 1) Periksa Apartment 03. 2) Ambil key dan survival supply. 3) Buka jalur yang terkunci. 4) Pelajari perilaku The Tenant. 5) Simpan jurnal atau catatan yang menjelaskan fasilitas.\nRISIKO: Jangan menghabiskan baterai di area terang. Jangan berasumsi monster sudah pergi hanya karena berhenti bergerak.\nALASAN MISI: Pada awalnya kamu hanya ingin keluar. Petunjuk yang ditemukan nanti akan menunjukkan bahwa keluar saja tidak cukup."

func _outside_mission(player: CharacterBody3D, outside: Node) -> String:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    var generator_running: bool = bool(outside.get("shelter_powered"))
    var generator_fuel: float = 0.0
    if shelter != null:
        generator_running = generator_running or bool(shelter.get("generator_running"))
        generator_fuel = float(shelter.get("generator_fuel_seconds"))

    var night: bool = outside.has_method("is_night") and bool(outside.call("is_night"))
    var far_region: bool = player.global_position.z < -132.0

    if night:
        return "FOREST — NIGHT SURVIVAL\nTUJUAN UTAMA: Bertahan sampai daylight dan jangan kehilangan base.\nLANGKAH: 1) Prioritaskan protective light. 2) Keluar hanya untuk kebutuhan penting. 3) Rawat bleeding/infection. 4) Kelola hunger/thirst/battery/fuel. 5) Jangan mengejar suara dari gelap.\nMASA DEPAN SISTEM: Weather, wildlife, hunting, fishing, cooking, dan temperature akan menambah alasan untuk merencanakan malam dari siang hari.\nALASAN MISI: Kamu membutuhkan base yang stabil sebelum mampu melakukan ekspedisi panjang untuk mencari jawaban."

    if not generator_running and generator_fuel <= 0.0:
        return "FOREST — BANGUN BASE PERTAMA\nTUJUAN UTAMA: Temukan cabin, Fuel Can, lalu hidupkan generator.\nLANGKAH: 1) Ikuti jalan ke cabin. 2) Periksa generator. 3) Cari Fuel Can. 4) Kumpulkan Battery/Food/Water/Medkit/Cloth. 5) Kembali dan hidupkan shelter.\nRISIKO: Jangan terlalu jauh menjelang malam tanpa rute pulang.\nALASAN MISI: Cabin akan menjadi pusat survival, storage, crafting, cooking, dan titik persiapan ekspedisi."

    if far_region:
        return "FOREST — SCOUTING & RESOURCE RUN\nTUJUAN UTAMA: Jelajahi wilayah terbengkalai sambil mencari suplai dan petunjuk menuju lokasi investigasi berikutnya.\nPRIORITAS RESOURCE: Fuel > Battery > Medical > Water > Food > Cloth/material.\nPRIORITAS INFORMASI: peta jalan • tanda rumah sakit • catatan laboratorium • museum records • cave survey • journal penyintas.\nRISIKO: Darkness, cold, luka, hunger/thirst, jarak dari base, dan night cycle dapat menumpuk sekaligus.\nALASAN MISI: Hutan adalah penghubung antara base dan dungeon/POI berikutnya. Setiap resource run harus perlahan membuka peta ekspedisi dunia."

    return "FOREST — DAYLIGHT SURVIVAL LOOP\nTUJUAN UTAMA: Gunakan siang untuk membuat dirimu mampu bertahan dan mampu pergi lebih jauh besok.\nSEKARANG: isi fuel • cari Food/Water/Medical/Battery/Cloth • rebus Dirty Water • rawat luka • kembali sebelum malam.\nROADMAP GAMEPLAY: hunting untuk meat/hide, fishing untuk food stabil, cooking untuk buff/keamanan makanan, weather untuk keputusan rute, wildlife untuk risiko/reward, crafting untuk perlengkapan ekspedisi.\nTUJUAN BESAR: Setelah base cukup kuat, ikuti petunjuk menuju Rumah Sakit, Museum, Laboratorium, Gua, dan Labyrinth lain. Cari jurnal/data dari masing-masing lokasi untuk menyusun solusi bagi umat manusia."

func _relay_count() -> int:
    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth == null:
        return 0
    var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
    var count: int = 0
    for value: Variant in relays.values():
        if bool(value):
            count += 1
    return count

func _count_arc_ids(values: Dictionary, ids: Array) -> int:
    var count: int = 0
    for id_variant: Variant in ids:
        if bool(values.get(str(id_variant), false)):
            count += 1
    return count
