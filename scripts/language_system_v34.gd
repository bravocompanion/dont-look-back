extends "res://scripts/language_system.gd"

const RANGER_MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const JOURNAL_SWITCH_NAME: String = "LanguageToggle"

const EXTRA_UI_EN_TO_ID: Dictionary = {
    "USE": "GUNAKAN",
    "RUN": "LARI",
    "LIGHT": "SENTER",
    "BATT": "BATERAI",
    "FOOD": "MAKAN",
    "WATER": "AIR",
    "MED": "OBAT",
    "JUMP": "LOMPAT",
    "RESTART": "ULANG",
    "STORE": "SIMPAN",
    "TAKE": "AMBIL",
    "CASE FILE": "BERKAS KASUS",
    "RANGER FIELD BASE": "BASE LAPANGAN RANGER",
    "SURVIVAL PLAN": "RENCANA SURVIVAL",
    "PRIMARY MISSION": "MISI UTAMA",
    "MISSION GUIDE": "PANDUAN MISI",
    "CASE EVIDENCE": "BUKTI KASUS",
    "FIELD SAMPLE": "SAMPEL LAPANGAN",
    "MINE LOG": "LOG TAMBANG",
    "INCIDENT": "INSIDEN",
    "ACCESS": "AKSES",
    "RESTRICTED": "TERBATAS",
    "SIGNAL": "SINYAL",
    "MAP": "PETA",
    "SURVIVAL": "SURVIVAL",
    "LORE": "LORE",
    "EXPEDITION BOARD": "PAPAN EKSPEDISI"
}

const EXTRA_EXACT_EN_TO_ID: Dictionary = {
    "Review Ranger Case Board": "Periksa Papan Kasus Ranger",
    "Enter Old Mine": "Masuk ke Tambang Tua",
    "Old Mine sealed — find the maintenance map": "Tambang Tua terkunci — cari peta maintenance",
    "Return to Ranger Forest": "Kembali ke Hutan Ranger",
    "Enter Labyrinth / Facility Level 03": "Masuk Labyrinth / Fasilitas Level 03",
    "Facility gate locked — find an access badge": "Gerbang fasilitas terkunci — cari badge akses",
    "Deeper route locked — more evidence required": "Jalur lebih dalam terkunci — butuh bukti tambahan",
    "Light campfire (Firewood/Wood)": "Nyalakan api unggun (Kayu Bakar/Kayu)",
    "The campfire needs Wood or a Firewood Bundle.": "Api unggun membutuhkan Kayu atau Bundel Kayu Bakar.",
    "Campfire fuel request sent to host.": "Permintaan bahan bakar api unggun dikirim ke host.",
    "Generator fuel tank is full.": "Tangki bahan bakar generator sudah penuh.",
    "You have no Fuel Can.": "Kamu tidak punya Jeriken Bahan Bakar.",
    "Fuel request sent to host.": "Permintaan bahan bakar dikirim ke host.",
    "Sleep until morning": "Tidur sampai pagi",
    "Sleep until morning (host only)": "Tidur sampai pagi (hanya host)",
    "Only the host can advance the shared night in v0.9.": "Hanya host yang dapat memajukan malam bersama.",
    "Shared storage (host controlled)": "Penyimpanan bersama (dikontrol host)",
    "Storage: STORE one supply": "Penyimpanan: SIMPAN satu suplai",
    "Storage: TAKE one supply": "Penyimpanan: AMBIL satu suplai",
    "Shared chest contents are synchronized; host controls transfers in v0.9.": "Isi peti bersama tersinkron; host mengontrol transfer.",
    "Craft Firewood Bundle (2 Wood)": "Buat Bundel Kayu Bakar (2 Kayu)",
    "Craft Improvised Battery (1 Wood + 2 Scrap)": "Buat Baterai Improvisasi (1 Kayu + 2 Besi Bekas)",
    "Craft Bandage (2 Cloth)": "Buat Perban (2 Kain)",
    "Crafted Firewood Bundle. Next: Improvised Battery.": "Bundel Kayu Bakar berhasil dibuat. Berikutnya: Baterai Improvisasi.",
    "Need 2 Wood. Next: Improvised Battery.": "Butuh 2 Kayu. Berikutnya: Baterai Improvisasi.",
    "Crafted Improvised Battery. Next: Bandage.": "Baterai Improvisasi berhasil dibuat. Berikutnya: Perban.",
    "Need 1 Wood + 2 Scrap. Next: Bandage.": "Butuh 1 Kayu + 2 Besi Bekas. Berikutnya: Perban.",
    "Crafted Bandage. Next: Firewood Bundle.": "Perban berhasil dibuat. Berikutnya: Bundel Kayu Bakar.",
    "Need 2 Cloth. Next: Firewood Bundle.": "Butuh 2 Kain. Berikutnya: Bundel Kayu Bakar.",
    "The generator is dry. Find a Fuel Can outside.": "Generator kehabisan bahan bakar. Cari Jeriken Bahan Bakar di luar.",
    "SHELTER ONLINE — Generator started. Checkpoint saved.": "BASE AKTIF — Generator menyala. Checkpoint tersimpan.",
    "Fuel added to the shelter generator.": "Bahan bakar ditambahkan ke generator base.",
    "You feed the campfire with a Firewood Bundle.": "Kamu menambah Bundel Kayu Bakar ke api unggun.",
    "You add loose wood to the campfire.": "Kamu menambahkan kayu lepas ke api unggun.",
    "The campfire needs Wood or a crafted Firewood Bundle.": "Api unggun membutuhkan Kayu atau Bundel Kayu Bakar hasil crafting.",
    "No survival supplies available to store.": "Tidak ada suplai survival yang dapat disimpan.",
    "The storage chest is empty.": "Peti penyimpanan kosong.",
    "It is too early to sleep. Prepare the shelter before night.": "Masih terlalu awal untuk tidur. Siapkan base sebelum malam.",
    "Not enough light fuel to survive the night. Refuel the generator or campfire.": "Bahan bakar cahaya tidak cukup untuk melewati malam. Isi generator atau api unggun.",
    "You survived the night. Morning light returns. Checkpoint saved.": "Kamu berhasil melewati malam. Cahaya pagi kembali. Checkpoint tersimpan.",
    "The shelter generator ran out of fuel.": "Generator base kehabisan bahan bakar.",
    "Cooking rack": "Rak memasak",
    "Cooking rack — light the campfire first": "Rak memasak — nyalakan api unggun terlebih dahulu",
    "Cook Raw Meat": "Masak Daging Mentah",
    "Cook Raw Fish": "Masak Ikan Mentah",
    "Cooking rack — no raw food": "Rak memasak — tidak ada makanan mentah",
    "The cooking rack is cold. Light the campfire before cooking.": "Rak memasak masih dingin. Nyalakan api unggun sebelum memasak.",
    "You have no Raw Meat or Raw Fish to cook.": "Kamu tidak punya Daging Mentah atau Ikan Mentah untuk dimasak.",
    "Inventory full. The raw food stays on the cooking rack.": "Inventaris penuh. Makanan mentah tetap berada di rak memasak.",
    "Fishing spot — but you need a Fishing Rod": "Tempat memancing — kamu membutuhkan Pancing",
    "Fish here": "Memancing di sini",
    "Collect Dirty Water": "Ambil Air Kotor",
    "The hand pump needs a moment before more water can be collected.": "Pompa tangan perlu waktu sebelum air dapat diambil lagi.",
    "Inventory full. Make room before collecting water.": "Inventaris penuh. Kosongkan ruang sebelum mengambil air.",
    "You collect Dirty Water. Boil it at the shelter campfire before drinking if possible.": "Kamu mengambil Air Kotor. Rebus di api unggun base sebelum diminum jika memungkinkan.",
    "Boil Dirty Water": "Rebus Air Kotor",
    "Carcass already harvested": "Bangkai sudah dipanen",
    "Empty survival cache": "Cache survival kosong",
    "Search old ranger survival cache": "Periksa cache survival ranger lama",
    "The ranger cache is useful, but your inventory has no room for its equipment.": "Cache ranger berguna, tetapi inventarismu tidak memiliki ruang untuk perlengkapannya.",
    "Dirty Water": "Air Kotor",
    "Wood": "Kayu",
    "Scrap": "Besi Bekas",
    "Fuel Can": "Jeriken Bahan Bakar",
    "Firewood Bundle": "Bundel Kayu Bakar",
    "Improvised Battery": "Baterai Improvisasi",
    "Raw Meat": "Daging Mentah",
    "Cooked Meat": "Daging Matang",
    "Raw Fish": "Ikan Mentah",
    "Cooked Fish": "Ikan Matang",
    "Hunting Bow": "Busur Berburu",
    "Hunting Knife": "Pisau Berburu",
    "Fishing Rod": "Pancing",
    "Arrow": "Panah",
    "Hide": "Kulit",
    "Bone": "Tulang",
    "Fat": "Lemak",
    "Deer": "Rusa",
    "Rabbit": "Kelinci",
    "Boar": "Babi Hutan",
    "Wolf": "Serigala",
    "Revive Survivor": "Bangkitkan Survivor",
    "Ranger Case Board": "Papan Kasus Ranger",
    "Survey Team Manifest": "Manifest Tim Survey",
    "Broken Radio Frequency Log": "Log Frekuensi Radio Rusak",
    "Maintenance Map — Old Mine": "Peta Maintenance — Tambang Tua",
    "Cold Water Sample Note": "Catatan Sampel Air Dingin",
    "Foreman's Last Shift": "Shift Terakhir Foreman",
    "Sealed Shaft Incident Report": "Laporan Insiden Shaft Tersegel",
    "Facility Access Badge T-03": "Badge Akses Fasilitas T-03",
    "Restricted Facility Routing Table": "Tabel Routing Fasilitas Terbatas",
    "Old Mine Shaft 03": "Tambang Tua Shaft 03",
    "Facility Gate / Labyrinth": "Gerbang Fasilitas / Labyrinth",
    "Routing Terminal": "Terminal Routing",
    "Deeper Containment Route": "Jalur Containment Lebih Dalam",
    "Return to Forest": "Kembali ke Hutan"
}

const EXTRA_PHRASE_EN_TO_ID: Array[PackedStringArray] = [
    PackedStringArray(["Read ", "Baca "]),
    PackedStringArray(["Inspect evidence: ", "Periksa bukti: "]),
    PackedStringArray([" — reviewed", " — sudah diperiksa"]),
    PackedStringArray(["Feed campfire (", "Tambah bahan bakar api unggun ("]),
    PackedStringArray(["Refuel generator (", "Isi bahan bakar generator ("]),
    PackedStringArray(["Start Shelter Generator (Fuel Can)", "Nyalakan Generator Base (Jeriken Bahan Bakar)"]),
    PackedStringArray(["Stored ", "Disimpan: "]),
    PackedStringArray(["Chest now holds ", "Peti sekarang menyimpan "]),
    PackedStringArray(["Inventory full. Cannot take ", "Inventaris penuh. Tidak dapat mengambil "]),
    PackedStringArray(["Took ", "Mengambil "]),
    PackedStringArray([" from storage. Chest holds ", " dari penyimpanan. Isi peti "]),
    PackedStringArray(["Storage action failed. Mode changed to ", "Aksi penyimpanan gagal. Mode berubah menjadi "]),
    PackedStringArray(["Water source recovering (", "Sumber air pulih kembali ("]),
    PackedStringArray(["Harvest ", "Panen bangkai "]),
    PackedStringArray([" carcass (Hunting Knife)", " (Pisau Berburu)"]),
    PackedStringArray(["Revive ", "Bangkitkan "]),
    PackedStringArray(["Survivor ", "Survivor "]),
    PackedStringArray(["RANGER CACHE: ", "CACHE RANGER: "]),
    PackedStringArray(["Kill prey with the bow, then harvest the carcass with the knife.", "Buru hewan dengan busur, lalu panen bangkainya dengan pisau."]),
    PackedStringArray([" Arrows", " Panah"]),
    PackedStringArray([" is cooked over the campfire and is now safe to eat.", " sudah dimasak di api unggun dan sekarang aman dimakan."]),
    PackedStringArray(["Checkpoint saved", "Checkpoint tersimpan"]),
    PackedStringArray(["checkpoint saved", "checkpoint tersimpan"]),
    PackedStringArray(["CURRENT MISSION", "MISI SAAT INI"]),
    PackedStringArray(["OBJECTIVE:", "TUJUAN:"]),
    PackedStringArray(["CONTEXT:", "KONTEKS:"]),
    PackedStringArray(["RULE:", "ATURAN:"]),
    PackedStringArray(["RESULT:", "HASIL:"]),
    PackedStringArray(["AFTER COMPLETION:", "SETELAH SELESAI:"]),
    PackedStringArray(["SAFE ZONE:", "ZONA AMAN:"]),
    PackedStringArray(["ROUTE:", "RUTE:"]),
    PackedStringArray(["Forest", "Hutan"]),
    PackedStringArray(["Old Mine", "Tambang Tua"]),
    PackedStringArray(["Research Facility", "Fasilitas Riset"]),
    PackedStringArray(["Abandoned House", "Rumah Kosong"]),
    PackedStringArray(["Old Gas Station", "SPBU Tua"]),
    PackedStringArray(["Warehouse", "Gudang"]),
    PackedStringArray(["Water Pump", "Pompa Air"]),
    PackedStringArray(["evidence", "bukti"]),
    PackedStringArray(["resource", "resource"]),
    PackedStringArray(["random resources", "resource acak"]),
    PackedStringArray(["hostile", "ancaman"]),
    PackedStringArray(["facility", "fasilitas"]),
    PackedStringArray(["maintenance map", "peta maintenance"]),
    PackedStringArray(["access badge", "badge akses"]),
    PackedStringArray(["survey team", "tim survey"]),
    PackedStringArray(["shaft", "shaft"]),
    PackedStringArray(["gate", "gerbang"]),
    PackedStringArray(["light", "cahaya"]),
    PackedStringArray(["battery", "baterai"]),
    PackedStringArray(["food", "makanan"]),
    PackedStringArray(["water", "air"]),
    PackedStringArray(["weather", "cuaca"]),
    PackedStringArray(["cold", "dingin"]),
    PackedStringArray(["hunting", "berburu"]),
    PackedStringArray(["fishing", "memancing"]),
    PackedStringArray(["cooking", "memasak"]),
    PackedStringArray(["safe base", "base aman"]),
    PackedStringArray(["safe zone", "zona aman"]),
    PackedStringArray(["Journal", "Jurnal"])
]

const JOURNAL_ENTRY_DATA: Dictionary = {
    "survival_basics": [
        "Cahaya Adalah Sumber Daya", "Light Is a Resource", "TIPS", "TIP",
        "Senter bukan hanya untuk melihat. Cahaya pelindung menurunkan Darkness Exposure dan dapat memaksa makhluk kegelapan mundur. Hemat baterai saat area sudah aman.",
        "A flashlight is not just for seeing. Protective light lowers Darkness Exposure and can force creatures of the dark to retreat. Save battery when the area is already safe."
    ],
    "world_premise": [
        "Kasus Ranger 07 — Tim Survey Hilang", "Ranger Case 07 — Missing Survey Team", "LORE", "LORE",
        "Kamu adalah ranger yang ditugaskan mencari jawaban setelah tim survey menghilang di hutan. Cabin adalah base operasi, bukan ending. Bertahan hidup lebih dulu, stabilkan shelter, lalu ikuti bukti dari lokasi ke lokasi. Jejak kasus mengarah dari Hutan ke Tambang Tua, kemudian ke fasilitas bawah tanah yang disebut Level 03 / Labyrinth.",
        "You are a ranger assigned to find answers after a survey team disappears in the forest. The cabin is your operating base, not the ending. Survive first, stabilize the shelter, then follow the evidence from location to location. The case trail leads from the Forest to the Old Mine, then into an underground facility known as Level 03 / the Labyrinth."
    ],
    "humanity_mission": [
        "Misi Jangka Panjang", "Long-Term Mission", "MISI UTAMA", "PRIMARY MISSION",
        "FASE 1 — SURVIVE: kuasai cabin, makanan, air, bahan bakar, cahaya, cuaca, berburu, dan dingin.\n\nFASE 2 — INVESTIGATE FOREST: Rumah Kosong → SPBU Tua → Gudang → opsional Pompa Air.\n\nFASE 3 — OLD MINE: cari log pekerja, laporan shaft, dan Facility Access Badge.\n\nFASE 4 — LABYRINTH: pulihkan sistem, pahami T-03, dan bawa data keluar.\n\nFASE 5 — RESEARCH NETWORK: ikuti routing table menuju Hospital, Museum, Laboratory, Cave, dan node lain.\n\nTujuan akhir bukan sekadar kabur; ranger harus menyusun bukti yang menjelaskan bagaimana manusia dapat bertahan dari fenomena ini.",
        "PHASE 1 — SURVIVE: master the cabin, food, water, fuel, light, weather, hunting, and cold.\n\nPHASE 2 — INVESTIGATE FOREST: Abandoned House → Old Gas Station → Warehouse → optional Water Pump.\n\nPHASE 3 — OLD MINE: find worker logs, shaft reports, and the Facility Access Badge.\n\nPHASE 4 — LABYRINTH: restore the systems, understand T-03, and bring the data out.\n\nPHASE 5 — RESEARCH NETWORK: follow the routing table toward the Hospital, Museum, Laboratory, Cave, and other nodes.\n\nThe final goal is not merely escape; the ranger must assemble evidence explaining how humanity can survive the phenomenon."
    ],
    "creature_rules": [
        "Aturan yang Ditinggalkan Penyintas", "Rules Left by Survivors", "SURVIVAL", "SURVIVAL",
        "1. The Tenant bergerak saat perhatianmu lepas. Melihatnya memberi waktu; cahaya memberi ruang.\n\n2. Darkness bukan sekadar kurang cahaya. Exposure yang lama membuat makhluk gelap dapat mendekat dan menyerang.\n\n3. Mourner mengikuti suara. Sprint dan interaksi keras bisa menyelamatkan beberapa detik sekaligus memberitahu posisimu.\n\n4. Crawler menghukum stamina kosong dan koridor sempit.\n\n5. Luka tidak selesai setelah serangan. Bleeding dan Infection bisa membunuh jauh setelah monster pergi.\n\n6. Hutan punya ancamannya sendiri: kelaparan, dehidrasi, suhu, cuaca, penyakit, hewan liar, malam, dan jarak dari shelter.\n\n7. Tidak semua perjalanan harus dilakukan. Kadang keputusan paling penting adalah pulang sebelum malam.",
        "1. The Tenant moves when your attention leaves it. Watching it buys time; light buys space.\n\n2. Darkness is more than the absence of light. Prolonged exposure allows dark creatures to approach and attack.\n\n3. The Mourner follows sound. Sprinting and loud interactions can save seconds while also revealing your position.\n\n4. The Crawler punishes empty stamina and tight corridors.\n\n5. Wounds do not end when an attack does. Bleeding and Infection can kill long after the monster is gone.\n\n6. The forest has its own threats: hunger, dehydration, temperature, weather, disease, wildlife, night, and distance from shelter.\n\n7. Not every trip should be completed. Sometimes the most important decision is returning before night."
    ],
    "route_overview": [
        "Rute Investigasi Utama", "Main Investigation Route", "PANDUAN MISI", "MISSION GUIDE",
        "START — Ranger Cabin: jadikan halaman 30×30 m sebagai base aman.\n\nFOREST CASE — Rumah Kosong → SPBU Tua → Gudang → Tambang Tua. Pompa Air memberi bukti samping.\n\nOLD MINE — Foreman's Log → Sealed Shaft Report → Facility Access Badge → Gate Level 03.\n\nLABYRINTH — emergency relays → Maintenance → Flooded Service → Archive → Lockdown.\n\nRESTRICTED FACILITY — routing terminal membuka daftar ekspedisi berikutnya. Setiap lokasi adalah scene terpisah agar gameplay, spawn, dan aset tidak bocor antar-map.",
        "START — Ranger Cabin: use the 30×30 m yard as a safe base.\n\nFOREST CASE — Abandoned House → Old Gas Station → Warehouse → Old Mine. The Water Pump provides optional side evidence.\n\nOLD MINE — Foreman's Log → Sealed Shaft Report → Facility Access Badge → Level 03 Gate.\n\nLABYRINTH — emergency relays → Maintenance → Flooded Service → Archive → Lockdown.\n\nRESTRICTED FACILITY — the routing terminal opens the next expedition list. Each location is a separate scene so gameplay, spawns, and assets do not leak between maps."
    ],
    "expedition_targets": [
        "Lokasi yang Harus Dicari", "Locations to Find", "PAPAN EKSPEDISI", "EXPEDITION BOARD",
        "RUMAH SAKIT — catatan medis, mutasi pasien, generator emergency, obat dan data korban pertama.\n\nMUSEUM — artefak lama yang menunjukkan fenomena ini mungkin sudah muncul jauh sebelum fasilitas modern dibangun.\n\nLABORATORIUM — data eksperimen, sampel, protokol T-03, dan kemungkinan metode containment.\n\nGUA — sumber geologis/biologis yang tidak bisa dijelaskan oleh catatan fasilitas. Tanpa listrik, cahaya menjadi resource utama.\n\nLABYRINTH LAIN — simpul fenomena dengan aturan ruang berbeda. Bisa menyimpan perangkat atau informasi yang dibutuhkan untuk endgame.\n\nLokasi-lokasi ini bukan dungeon acak. Setiap ekspedisi harus memberi jawaban baru sekaligus membuka pertanyaan berikutnya.",
        "HOSPITAL — medical records, patient mutations, emergency generators, medicine, and data from the first victims.\n\nMUSEUM — old artifacts suggesting the phenomenon may have appeared long before the modern facility was built.\n\nLABORATORY — experiment data, samples, T-03 protocols, and possible containment methods.\n\nCAVE — a geological or biological source that facility records cannot explain. Without electricity, light becomes the primary resource.\n\nOTHER LABYRINTHS — phenomenon nodes with different spatial rules. They may contain devices or information required for the endgame.\n\nThese locations are not random dungeons. Every expedition should provide a new answer while opening the next question."
    ],
    "forest_survival_plan": [
        "Rencana Operasi Ranger", "Ranger Operations Plan", "RENCANA SURVIVAL", "SURVIVAL PLAN",
        "Cabin menghadap ke pusat hutan. Siapkan ekspedisi dari halaman aman, keluar melalui gate sisi hutan, kumpulkan resource dan bukti, lalu kembali sebelum kegelapan, cuaca, dingin, dan jarak menghabiskan persediaan. Resource acak dan ancaman tidak spawn di halaman/cabin; perlengkapan base tetap boleh ada sebagai infrastruktur ranger.",
        "The cabin faces toward the center of the forest. Prepare expeditions from the secure yard, leave through the forest-side gate, collect resources and evidence, then return before darkness, weather, cold, and travel distance consume your supplies. Random resources and hostiles do not spawn in the yard/cabin; fixed base equipment remains as ranger infrastructure."
    ],
    "apartment_scribble": [
        "Coretan di Balik Laci", "Scribble Behind the Drawer", "TIPS", "TIP",
        "Ia hanya bergerak saat tidak ada yang melihat. Aku mencoba cermin. Cermin tidak dihitung. Sepasang mata yang hidup dihitung.",
        "It only moves when nobody is looking. I tried mirrors. The mirror did not count. A living pair of eyes did."
    ],
    "relay_memo": [
        "Memo Relay Darurat", "Emergency Relay Memo", "CATATAN MISI", "MISSION NOTE",
        "Tiga relay darurat memberi daya ke gerbang terakhir. Aturan maintenance: pulihkan satu per satu dan jangan pernah melintasi koridor servis gelap tanpa lampu yang berfungsi.",
        "Three emergency relays feed the final gate. Maintenance rule: restore them one at a time and never cross the dark service corridor without a working lamp."
    ],
    "cabin_ledger": [
        "Catatan Bahan Bakar Cabin", "Cabin Fuel Ledger", "LOG", "LOG",
        "Persediaan bahan bakar berhenti dicatat tiga musim dingin lalu. Entri terakhir berbunyi: 'Jaga lampu beranda tetap menyala. Mereka berhenti di batas cahayanya, bahkan saat generator terdengar seperti seharusnya sudah mati.'",
        "Fuel inventory ended three winters ago. The final entry says: 'Keep the porch light burning. Things stop at the edge of it, even when the generator sounds like it should be dead.'"
    ],
    "gas_station_receipt": [
        "Struk #0313", "Receipt #0313", "TRIVIA", "TRIVIA",
        "Penanda mil di jalan tua melewati angka 13, tetapi setiap struk dari stasiun ini berakhir dengan 13. Struk ini mencantumkan baterai, makanan kaleng, dan satu barang yang hanya ditulis 'JANGAN MENENGOK'.",
        "The old road's mile markers skip 13, but every receipt from this station ends in 13. This one lists batteries, canned food, and one item simply written as 'DO NOT TURN AROUND'."
    ],
    "warehouse_warning": [
        "Peringatan Malam Gudang", "Warehouse Night Notice", "PERINGATAN", "WARNING",
        "Kru malam: pastikan cahaya lorong saling tumpang tindih. Celah gelap di antara dua lampu tetaplah tempat gelap. Jika seseorang memanggil namamu dari lorong tanpa cahaya, hitung orang di sampingmu sebelum menjawab.",
        "Night crew: keep aisle lights overlapping. A dark gap between two lamps is still a dark place. If someone calls your name from an unlit aisle, count the people beside you before answering."
    ],
    "pump_card": [
        "Kartu Servis Pompa Tangan", "Hand Pump Service Card", "TIPS", "TIP",
        "Air tanah tidak aman tanpa pengolahan. Rebus di atas api yang stabil. Air yang jernih tidak sama dengan air yang bersih.",
        "The groundwater is not safe untreated. Boil it over a sustained fire. Clear water is not the same thing as clean water."
    ],
    "investigation_survey_manifest": [
        "Manifest Tim Survey", "Survey Team Manifest", "BUKTI KASUS", "CASE EVIDENCE",
        "Empat anggota tim survey meninggalkan ranger station menuju rumah kosong di sektor barat. Catatan terakhir menyebut mereka berencana mencari radio kendaraan di SPBU tua setelah menemukan simbol tambang pada dinding basement.",
        "Four survey team members left the ranger station for the abandoned house in the western sector. Their final note says they planned to look for the vehicle radio at the old gas station after finding a mine symbol on the basement wall."
    ],
    "investigation_radio_trace": [
        "Log Frekuensi Radio Rusak", "Broken Radio Frequency Log", "SINYAL", "SIGNAL",
        "Radio tua merekam burst pendek pada frekuensi maintenance. Koordinatnya mengarah ke gudang lama. Pesan yang tersisa hanya: 'shaft access... map cabinet... do not use the main road after dark.'",
        "The old radio recorded a short burst on the maintenance frequency. Its coordinates point to the old warehouse. The remaining message says only: 'shaft access... map cabinet... do not use the main road after dark.'"
    ],
    "investigation_maintenance_map": [
        "Peta Maintenance — Tambang Tua", "Maintenance Map — Old Mine", "PETA", "MAP",
        "Peta gudang menunjukkan jalur servis menuju sebuah mine shaft di sudut barat-daya hutan. Di bawah simbol tambang ada jalur lain yang diberi label FACILITY ACCESS / LEVEL 03.",
        "The warehouse map shows a service path to a mine shaft in the southwest corner of the forest. Beneath the mine symbol is another route labeled FACILITY ACCESS / LEVEL 03."
    ],
    "investigation_water_sample": [
        "Catatan Sampel Air Dingin", "Cold Water Sample Note", "SAMPEL LAPANGAN", "FIELD SAMPLE",
        "Air pompa tetap beberapa derajat lebih dingin dari udara sekitar dan menyebabkan sensor cahaya ranger berkedip. Fenomena yang sama disebut dalam laporan fasilitas bawah tanah.",
        "The pump water stays several degrees colder than the surrounding air and makes the ranger light sensor flicker. The same phenomenon is mentioned in underground facility reports."
    ],
    "investigation_foreman_log": [
        "Shift Terakhir Foreman", "Foreman's Last Shift", "LOG TAMBANG", "MINE LOG",
        "Tim tambang menemukan pintu logam yang tidak tercantum pada izin penggalian. Setelah pintu itu terbuka, pekerja mulai melaporkan lorong yang berubah panjang ketika lampu dimatikan.",
        "The mining crew found a metal door not listed on the excavation permit. After it was opened, workers began reporting corridors that changed length when the lights were switched off."
    ],
    "investigation_sealed_shaft_report": [
        "Laporan Insiden Shaft Tersegel", "Sealed Shaft Incident Report", "INSIDEN", "INCIDENT",
        "Shaft terdalam ditutup setelah tiga pekerja menghilang dalam jarak kurang dari dua puluh meter. Tim recovery menemukan helm dan lampu mereka, tetapi tidak menemukan jejak keluar dari terowongan.",
        "The deepest shaft was sealed after three workers vanished within less than twenty meters. The recovery team found their helmets and lamps, but no tracks leading out of the tunnel."
    ],
    "investigation_facility_badge": [
        "Badge Akses Fasilitas T-03", "Facility Access Badge T-03", "AKSES", "ACCESS",
        "Badge milik teknisi fasilitas berada di dekat gerbang bawah tambang. Kode T-03 cocok dengan referensi fenomena occupancy pada catatan lama. Badge ini membuka jalur menuju Labyrinth.",
        "A facility technician's badge lies near the lower mine gate. The T-03 code matches old references to the occupancy phenomenon. This badge opens the route to the Labyrinth."
    ],
    "investigation_facility_terminal": [
        "Tabel Routing Fasilitas Terbatas", "Restricted Facility Routing Table", "TERBATAS", "RESTRICTED",
        "Data dari Labyrinth mengarah ke jaringan lokasi lain: rumah sakit, museum, laboratorium containment, sistem gua, dan beberapa simpul Labyrinth lain. Hutan hanyalah base pertama; investigasi baru dimulai.",
        "Data from the Labyrinth points to a network of other locations: a hospital, museum, containment laboratory, cave system, and several other Labyrinth nodes. The forest is only the first base; the investigation has just begun."
    ]
}

var extra_reverse_ui: Dictionary = {}
var extra_reverse_exact: Dictionary = {}
var top_menu_switch: Button
var top_journal_switch: Button

func _ready() -> void:
    super._ready()
    process_priority = 220
    _build_extra_reverse_maps()

func _load_language() -> void:
    language_code = "id"
    var config: ConfigFile = ConfigFile.new()
    if config.load(LANGUAGE_PATH) != OK:
        return
    var saved: String = str(config.get_value("language", "locale", ""))
    if saved.is_empty():
        saved = str(config.get_value("localization", "language", "id"))
    saved = saved.to_lower()
    if SUPPORTED_LANGUAGES.has(saved):
        language_code = saved

func _save_language() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("language", "locale", language_code)
    config.set_value("localization", "language", language_code)
    config.save(LANGUAGE_PATH)

func _input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event as InputEventKey
    if not key_event.pressed or key_event.echo or key_event.physical_keycode != KEY_L:
        return
    var focus: Control = get_viewport().gui_get_focus_owner()
    if focus is LineEdit:
        return
    _toggle_language()
    get_viewport().set_input_as_handled()

func _build_extra_reverse_maps() -> void:
    extra_reverse_ui.clear()
    for english_variant: Variant in EXTRA_UI_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        extra_reverse_ui[str(EXTRA_UI_EN_TO_ID[english_variant])] = english_text
    extra_reverse_exact.clear()
    for english_variant: Variant in EXTRA_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        extra_reverse_exact[str(EXTRA_EXACT_EN_TO_ID[english_variant])] = english_text

func _ensure_language_controls() -> void:
    super._ensure_language_controls()
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        var settings_box: VBoxContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel/VBox") as VBoxContainer
        var settings_panel: PanelContainer = scene.get_node_or_null("MenuLayer/Root/Center/SettingsPanel") as PanelContainer
        _ensure_button_in_box(settings_box, settings_panel)
        _ensure_top_menu_switch(scene)
    else:
        top_menu_switch = null
        _ensure_top_journal_switch()

func _ensure_top_menu_switch(scene: Node) -> void:
    var root: Control = scene.get_node_or_null("MenuLayer/Root") as Control
    if root == null:
        return
    top_menu_switch = root.get_node_or_null(JOURNAL_SWITCH_NAME) as Button
    if top_menu_switch == null:
        top_menu_switch = Button.new()
        top_menu_switch.name = JOURNAL_SWITCH_NAME
        top_menu_switch.focus_mode = Control.FOCUS_NONE
        top_menu_switch.anchor_left = 1.0
        top_menu_switch.anchor_right = 1.0
        top_menu_switch.offset_left = -184.0
        top_menu_switch.offset_top = 12.0
        top_menu_switch.offset_right = -12.0
        top_menu_switch.offset_bottom = 50.0
        top_menu_switch.add_theme_font_size_override("font_size", 13)
        top_menu_switch.pressed.connect(_toggle_language)
        root.add_child(top_menu_switch)
    top_menu_switch.visible = true
    _set_language_button_text(top_menu_switch)

func _ensure_top_journal_switch() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        top_journal_switch = null
        return
    var layer_value: Variant = journal.get("layer")
    if not (layer_value is CanvasLayer):
        return
    var layer: CanvasLayer = layer_value as CanvasLayer
    top_journal_switch = layer.get_node_or_null(JOURNAL_SWITCH_NAME) as Button
    if top_journal_switch == null:
        top_journal_switch = Button.new()
        top_journal_switch.name = JOURNAL_SWITCH_NAME
        top_journal_switch.focus_mode = Control.FOCUS_NONE
        top_journal_switch.anchor_left = 1.0
        top_journal_switch.anchor_right = 1.0
        top_journal_switch.offset_left = -184.0
        top_journal_switch.offset_top = 12.0
        top_journal_switch.offset_right = -12.0
        top_journal_switch.offset_bottom = 50.0
        top_journal_switch.add_theme_font_size_override("font_size", 13)
        top_journal_switch.pressed.connect(_toggle_language)
        layer.add_child(top_journal_switch)
    top_journal_switch.visible = journal.has_method("is_open") and bool(journal.call("is_open"))
    _set_language_button_text(top_journal_switch)

func _set_language_button_text(button: Button) -> void:
    if button == null:
        return
    button.text = "BAHASA: INDONESIA" if language_code == "id" else "LANGUAGE: ENGLISH"
    button.tooltip_text = "Ganti ke English • shortcut L" if language_code == "id" else "Switch to Bahasa Indonesia • shortcut L"

func _apply_localization() -> void:
    super._apply_localization()
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    if scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        _localize_main_menu(scene)
    _localize_current_hud_extras()
    _localize_mobile_controls()
    _localize_world_labels(scene)
    _sync_journal_entries()
    _sync_world_note_sources()
    if top_menu_switch != null and is_instance_valid(top_menu_switch):
        _set_language_button_text(top_menu_switch)
    if top_journal_switch != null and is_instance_valid(top_journal_switch):
        _set_language_button_text(top_journal_switch)

func _localize_control(node: Node) -> void:
    super._localize_control(node)
    if node is Control:
        var control: Control = node as Control
        if not control.tooltip_text.is_empty():
            control.tooltip_text = localize_gameplay_text(control.tooltip_text)

func _localize_ui_exact(text: String) -> String:
    var canonical: String = str(extra_reverse_ui.get(text, text))
    canonical = str(extra_reverse_exact.get(canonical, canonical))
    var parent_result: String = super._localize_ui_exact(canonical)
    if language_code == "en":
        return str(extra_reverse_ui.get(parent_result, extra_reverse_exact.get(parent_result, parent_result)))
    if EXTRA_UI_EN_TO_ID.has(canonical):
        return str(EXTRA_UI_EN_TO_ID[canonical])
    if EXTRA_EXACT_EN_TO_ID.has(canonical):
        return str(EXTRA_EXACT_EN_TO_ID[canonical])
    return parent_result

func _localize_status(text: String) -> String:
    var canonical: String = str(extra_reverse_exact.get(text, text))
    var parent_result: String = super._localize_status(canonical)
    if language_code == "id" and EXTRA_EXACT_EN_TO_ID.has(canonical):
        return str(EXTRA_EXACT_EN_TO_ID[canonical])
    if language_code == "en" and extra_reverse_exact.has(text):
        return canonical
    return parent_result

func _canonicalize_text(text: String) -> String:
    var result: String = super._canonicalize_text(text)
    if extra_reverse_exact.has(result):
        result = str(extra_reverse_exact[result])
    for pair: PackedStringArray in EXTRA_PHRASE_EN_TO_ID:
        result = result.replace(pair[1], pair[0])
    for id_variant: Variant in extra_reverse_ui.keys():
        var id_text: String = str(id_variant)
        result = result.replace(id_text, str(extra_reverse_ui[id_variant]))
    return result

func _translate_gameplay_to_indonesian(text: String) -> String:
    if EXTRA_EXACT_EN_TO_ID.has(text):
        return str(EXTRA_EXACT_EN_TO_ID[text])
    var result: String = super._translate_gameplay_to_indonesian(text)
    for pair: PackedStringArray in EXTRA_PHRASE_EN_TO_ID:
        result = result.replace(pair[0], pair[1])
    for english_variant: Variant in EXTRA_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        result = result.replace(english_text, str(EXTRA_EXACT_EN_TO_ID[english_variant]))
    return result

func get_journal_entry_data(entry_id: String) -> Dictionary:
    if not JOURNAL_ENTRY_DATA.has(entry_id):
        return {}
    var row: Array = Array(JOURNAL_ENTRY_DATA[entry_id])
    if row.size() < 6:
        return {}
    var id_mode: bool = language_code == "id"
    return {
        "title": str(row[0] if id_mode else row[1]),
        "category": str(row[2] if id_mode else row[3]),
        "body": str(row[4] if id_mode else row[5])
    }

func _sync_journal_entries() -> void:
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal == null:
        return
    var entries_value: Variant = journal.get("entries")
    if not (entries_value is Dictionary):
        return
    var entries_dict: Dictionary = Dictionary(entries_value).duplicate(true)
    var changed: bool = false
    for entry_variant: Variant in JOURNAL_ENTRY_DATA.keys():
        var entry_id: String = str(entry_variant)
        if not entries_dict.has(entry_id):
            continue
        entries_dict[entry_id] = get_journal_entry_data(entry_id)
        changed = true
    if changed:
        journal.set("entries", entries_dict)
        if journal.has_method("is_open") and bool(journal.call("is_open")) and journal.has_method("_update_entry_display"):
            journal.call("_update_entry_display")

func _sync_world_note_sources() -> void:
    for node: Node in get_tree().get_nodes_in_group("journal_note"):
        if node == null or not is_instance_valid(node):
            continue
        var entry_id: String = str(node.get("entry_id"))
        var data: Dictionary = get_journal_entry_data(entry_id)
        if data.is_empty():
            continue
        node.set("entry_title", str(data.get("title", "")))
        node.set("entry_category", str(data.get("category", "")))
        node.set("entry_body", str(data.get("body", "")))

func _localize_current_hud_extras() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var case_file: Label = player.get_node_or_null("HUD/CaseFile") as Label
    if case_file != null:
        case_file.text = localize_gameplay_text(case_file.text)
    var shelter_status: Label = player.get_node_or_null("HUD/ShelterStatus") as Label
    if shelter_status != null:
        shelter_status.text = localize_gameplay_text(shelter_status.text)
    var top_bar: Control = player.get_node_or_null("HUD/TopStatusBarV32") as Control
    if top_bar != null:
        for node: Node in top_bar.find_children("*", "Label", true, false):
            var label: Label = node as Label
            if label != null:
                label.text = _localize_stat_line(label.text)
    var end_panel: Control = player.get_node_or_null("HUD/EndPanel") as Control
    if end_panel != null:
        _localize_control_tree(end_panel)

func _localize_mobile_controls() -> void:
    var mobile: Node = get_node_or_null("/root/MobileControls")
    if mobile == null:
        return
    var layer_value: Variant = mobile.get("layer")
    if not (layer_value is CanvasLayer):
        return
    var layer: CanvasLayer = layer_value as CanvasLayer
    for node: Node in layer.find_children("*", "Button", true, false):
        var button: Button = node as Button
        if button == null:
            continue
        button.text = _localize_ui_exact(button.text)

func _localize_world_labels(scene: Node) -> void:
    for node: Node in scene.find_children("*", "Label3D", true, false):
        var label: Label3D = node as Label3D
        if label != null:
            label.text = localize_gameplay_text(label.text)

func _localize_inventory(text: String) -> String:
    var result: String = super._localize_inventory(text)
    for english_variant: Variant in EXTRA_EXACT_EN_TO_ID.keys():
        var english_text: String = str(english_variant)
        var id_text: String = str(EXTRA_EXACT_EN_TO_ID[english_variant])
        if language_code == "id":
            result = result.replace(english_text, id_text)
        else:
            result = result.replace(id_text, english_text)
    return result

func _localize_controls_text(text: String) -> String:
    var result: String = super._localize_controls_text(text)
    if language_code == "id":
        result = result.replace("Inspect/Use", "Periksa/Gunakan")
        result = result.replace("E Inspect", "E Periksa")
        result = result.replace("J Evidence Journal", "J Jurnal Bukti")
        result = result.replace("J Journal", "J Jurnal")
        result = result.replace("K Save", "K Simpan")
        result = result.replace("M Co-op", "M Co-op")
        return result
    result = result.replace("Periksa/Gunakan", "Inspect/Use")
    result = result.replace("E Periksa", "E Inspect")
    result = result.replace("J Jurnal Bukti", "J Evidence Journal")
    result = result.replace("J Jurnal", "J Journal")
    result = result.replace("K Simpan", "K Save")
    return result
