extends "res://scripts/journal_system.gd"

func _ready() -> void:
    super._ready()
    _add_entry(
        "world_premise",
        "Apa yang Terjadi di Sini?",
        "LORE",
        "Tidak ada satu malam ketika dunia tiba-tiba berakhir. Semuanya memburuk sedikit demi sedikit: lorong yang tidak cocok dengan blueprint, lampu yang mati tanpa gangguan listrik, orang yang mendengar namanya dipanggil dari ruangan kosong. Fasilitas bawah tanah mencoba mempelajari fenomena itu dan memberinya nomor SUBJEK T-03. Para teknisi memberi nama yang lebih sederhana: The Tenant. Setelah insiden 03:13, kegelapan mulai muncul jauh di luar fasilitas. Kamu bukan orang pertama yang mencoba keluar—hanya salah satu dari sedikit yang masih bergerak."
    )
    _add_entry(
        "creature_rules",
        "Aturan yang Ditinggalkan Penyintas",
        "SURVIVAL",
        "1. The Tenant bergerak saat perhatianmu lepas. Melihatnya memberi waktu; cahaya memberi ruang.\n\n2. Darkness bukan sekadar kurang cahaya. Exposure yang lama membuat makhluk gelap dapat mendekat dan menyerang.\n\n3. Mourner mengikuti suara. Sprint dan interaksi keras bisa menyelamatkan beberapa detik sekaligus memberitahu posisimu.\n\n4. Crawler menghukum stamina kosong dan koridor sempit.\n\n5. Luka tidak selesai setelah serangan. Bleeding dan Infection bisa membunuh jauh setelah monster pergi.\n\n6. Di luar, daylight adalah kesempatan kerja. Night adalah keadaan darurat."
    )
    _add_entry(
        "route_overview",
        "Rute Keluar — Ringkasan Bab",
        "MISSION GUIDE",
        "BAB I — Apartment 03: cari perlengkapan dan akses ke Lower Labyrinth.\n\nBAB II — Lower Labyrinth: hidupkan 3 emergency relay untuk membuka fasilitas inti.\n\nARC 1 / Maintenance: pulihkan Fuse A, B, C.\n\nARC 1 / Flooded Service: putar dua pressure valve.\n\nARC 1 / Archive: masukkan breaker B → A → C.\n\nARC 1 / Lockdown: persiapkan suplai, aktifkan console, bertahan 120 detik.\n\nBAB III — The Outside: temukan cabin, dapatkan fuel, hidupkan shelter, lalu gunakan siang untuk menjarah area sebelum night cycle."
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
            return "ARC 1 — MAINTENANCE WING\nTUJUAN UTAMA: Pulihkan tiga fuse box (%d / 3).\nLANGKAH: 1) Cari Fuse A/B/C. 2) Dengarkan arah Mourner sebelum sprint. 3) Gunakan pocket cahaya untuk reposisi. 4) Loot side route sebelum pintu berikutnya.\nRISIKO: Noise menarik Mourner; panic tinggi membuat gerak dan flashlight makin sulit dikendalikan.\nKENAPA: Fuse memberi daya ke Flooded Service dan membuka bagian fasilitas yang dikunci setelah insiden 03:13." % fuse_count
        if stage == 2:
            var valve_count: int = _count_arc_ids(completed, ["valve_a", "valve_b"])
            return "ARC 1 — FLOODED SERVICE\nTUJUAN UTAMA: Tutup dua pressure valve (%d / 2).\nLANGKAH: 1) Cari Valve A dan B. 2) Jangan ambil jalur gelap hanya karena lebih pendek. 3) Ambil suplai tersembunyi di cabang samping. 4) Sisakan stamina untuk keluar dari koridor sempit.\nRISIKO: Area basah memperburuk orientasi dan Crawler dapat memotong jalur ketika stamina rendah.\nKENAPA: Tekanan air harus turun sebelum Archive bisa menerima daya stabil." % valve_count
        if stage == 3:
            return "ARC 1 — ARCHIVE\nTUJUAN UTAMA: Masukkan breaker B → A → C. Progress %d / 3.\nLANGKAH: 1) Temukan ketiga panel. 2) Ingat urutan sebelum menyentuh panel pertama. 3) Setelah setiap breaker, cek jalur mundur dan kondisi baterai.\nRISIKO: Urutan salah memicu blackout alarm dan menaikkan aggression musuh.\nKENAPA: Archive memegang routing manual terakhir menuju Lockdown Console—dan catatan asli tentang SUBJEK T-03." % breaker_progress
        if stage == 4:
            return "ARC 1 — LOCKDOWN PREP\nTUJUAN UTAMA: Siapkan diri sebelum menyalakan console terakhir.\nCHECKLIST: Heal bila luka • minum • makan • baterai cukup • Bandage/Medkit tersedia • stamina penuh • kenali minimal dua pocket cahaya.\nRISIKO: Setelah console aktif, pintu terkunci dan proses tidak bisa dibatalkan dengan aman.\nKENAPA: Lockdown mencoba mengisolasi fenomena cukup lama agar final exit terbuka."
        if stage == 5 or holdout_active:
            var seconds: int = maxi(0, int(ceil(holdout_remaining)))
            return "ARC 1 — LOCKDOWN AKTIF\nTUJUAN UTAMA: Bertahan %d:%02d lagi.\nLANGKAH: 1) Bergerak antar pocket cahaya. 2) Jangan bertahan di sudut. 3) Gunakan stamina untuk reposisi, bukan berlari tanpa tujuan. 4) Simpan baterai untuk transisi gelap.\nRISIKO: Alarm memanggil Mourner/Crawler dan aggression meningkat selama stabilisasi.\nKENAPA: Kamu tidak perlu membunuh semuanya. Kamu hanya perlu hidup sampai sistem selesai." % [seconds / 60, seconds % 60]
        if stage >= 6:
            return "ARC 1 — EXIT TERBUKA\nTUJUAN UTAMA: Ikuti final beacon menuju permukaan.\nLANGKAH: 1) Ambil suplai terakhir yang aman. 2) Jangan buang health untuk loot kecil. 3) Masuk ke exit trigger dengan kondisi cukup untuk map berikutnya.\nRISIKO: Kematian sebelum transisi tetap kehilangan kemajuan sejak checkpoint terakhir.\nKENAPA: The Outside membawa hunger, thirst, luka, inventory, dan kebutuhan cahaya yang sama—hanya ruangnya lebih luas."

    var relay_count: int = _relay_count()
    if relay_count >= 3:
        return "LOWER LABYRINTH — GERBANG SIAP\nTUJUAN UTAMA: Ikuti beacon menuju Maintenance Wing.\nLANGKAH: Isi ulang kebutuhan sebelum melewati gerbang: baterai, air, makanan, medical supply.\nRISIKO: Area berikutnya memperkenalkan musuh yang bereaksi terhadap noise dan objective berantai.\nKENAPA: Tiga relay sudah memberi daya pada jalur fasilitas inti."

    if player.global_position.z < -15.0:
        return "BAB II — LOWER LABYRINTH\nTUJUAN UTAMA: Aktifkan 3 emergency relay (%d / 3).\nLANGKAH: 1) Cari cahaya/relay berikutnya. 2) Loot baterai dan suplai di cabang samping. 3) Jangan biarkan Darkness Exposure menumpuk. 4) Saat Tenant muncul, jaga perhatian dan cari ruang terang.\nRISIKO: Bergerak menaikkan panic; sprint menaikkannya lebih cepat. Baterai adalah resource, bukan kenyamanan.\nKENAPA: Relay adalah satu-satunya cara membuka gerbang yang memisahkan labyrinth lama dari fasilitas penelitian." % relay_count

    return "BAB I — APARTMENT 03\nTUJUAN UTAMA: Keluar dari koridor awal dan temukan akses menuju Lower Labyrinth.\nLANGKAH: 1) Periksa Apartment 03. 2) Ambil key dan survival supply. 3) Buka pintu yang menghalangi lorong. 4) Pelajari perilaku The Tenant sebelum masuk lebih dalam.\nRISIKO: Jangan menghabiskan baterai di area yang sudah diterangi. Jika sesuatu berhenti saat dilihat, jangan berasumsi ia sudah pergi.\nKENAPA: Apartment 03 adalah tempat petugas terakhir meninggalkan petunjuk tentang apa yang sebenarnya tinggal di gedung ini."

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
        return "BAB III — NIGHT CYCLE\nTUJUAN UTAMA: Bertahan sampai daylight kembali; shelter adalah prioritas.\nLANGKAH: 1) Tetap dekat protective light bila suplai rendah. 2) Kalau keluar, gunakan rute pendek antar lampu. 3) Jangan mengejar suara dari area gelap. 4) Rawat bleeding/infection sebelum menjadi damage berkala.\nRISIKO: Darkness lebih berbahaya, suhu turun, dan perjalanan pulang memakan baterai serta stamina.\nKENAPA: Catatan lokal menunjukkan serangan meningkat setelah bayangan kehilangan arah saat matahari turun."

    if not generator_running and generator_fuel <= 0.0:
        return "BAB III — CABIN TANPA DAYA\nTUJUAN UTAMA: Temukan Fuel Can dan hidupkan generator cabin.\nLANGKAH: 1) Ikuti jalan menuju cabin. 2) Periksa generator. 3) Cari Fuel Can di area terbengkalai. 4) Kumpulkan Battery/Food/Water/Medkit/Cloth sambil bergerak. 5) Kembali dan aktifkan shelter.\nRISIKO: Jangan terlalu jauh menjelang malam tanpa rute pulang.\nKENAPA: Cabin menjadi checkpoint dan lingkar cahaya permanen pertama di permukaan."

    if far_region:
        return "BAB III — ABANDONED REGION\nTUJUAN UTAMA: Loot gas station, warehouse, rumah kosong, dan sumber air tanpa kehilangan jalur pulang.\nPRIORITAS: Fuel > Battery > Medical > Water > Food > Cloth/material. Dirty Water harus direbus sebelum aman.\nLANGKAH: Tandai jalur kembali ke cabin sebelum masuk bangunan besar. Masuk warehouse hanya jika baterai dan stamina cukup.\nRISIKO: Blind spot, Darkness, cold exposure, bleeding, dan night cycle dapat menumpuk menjadi satu kegagalan.\nKENAPA: Komunitas di sini bertahan lama dengan jaringan lampu—dan runtuh ketika celah gelap mulai muncul di antara lampu-lampu itu."

    return "BAB III — DAYLIGHT WINDOW\nTUJUAN UTAMA: Gunakan siang untuk mempersiapkan malam berikutnya.\nLANGKAH: 1) Isi fuel shelter. 2) Cari Battery/Food/Water/Medical/Cloth. 3) Rebus Dirty Water. 4) Pulihkan health dan rawat bleeding/infection. 5) Kembali sebelum perjalanan pulang menjadi lebih mahal daripada loot yang dibawa.\nRISIKO: Daylight lebih aman, bukan aman sepenuhnya. Panic, hunger, thirst, dan luka tetap berjalan.\nKENAPA: Di luar fasilitas, survival bukan soal satu pintu keluar—melainkan membangun ritme hidup yang bisa bertahan beberapa hari."

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
