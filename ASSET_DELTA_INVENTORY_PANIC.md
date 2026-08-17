# Asset Delta — Inventory Menu + Movement Panic

## Update gameplay

### Panic movement
- Bergerak sekarang meningkatkan panic meter mulai dari kecepatan gerak kecil, bukan hanya saat sprint.
- Jalan normal menaikkan panic secara bertahap.
- Sprint menaikkan panic lebih cepat karena mendekati `movement_full_panic_speed`.
- Saat pemain benar-benar diam dan tidak melakukan input panik lain, panic tetap dapat turun.
- Tuning dipasang melalui `scripts/panic_movement_tuning_system.gd` tanpa mengubah `project.godot`.

### Inventory menu
- Label inventory lama di HUD disembunyikan.
- Semua item yang dimiliki pemain dibaca langsung dari `inventory_names` dan `inventory_counts` lalu ditampilkan di menu Inventory.
- Desktop: tekan `I` untuk buka/tutup inventory.
- Mobile: tombol `BAG` tersedia pada HUD.
- Consumable dapat dipakai langsung dari menu:
  - Canned Food
  - Bottled Water
  - Medkit
  - Flashlight Battery
- Item lain tetap tampil sebagai `KEY ITEM` sehingga tidak hilang dari inventory.
- Layout inventory menyesuaikan viewport mobile dan desktop.
- Saat menu terbuka, gerak local player dikunci; pada co-op dunia tetap dapat berjalan.

## Runtime integration
- `scripts/inventory_menu_system.gd`
- `scripts/panic_movement_tuning_system.gd`
- Keduanya dipasang oleh `scripts/survival_system.gd`.
- `project.godot` tidak perlu diubah.

## Asset yang dibutuhkan setelah update
Tidak ada asset wajib baru. Inventory menu saat ini menggunakan panel dan tombol procedural Godot sehingga langsung dapat berjalan.

### Optional polish berikutnya
- Ikon 64x64 untuk: canned food, bottled water, medkit, flashlight battery, key item, crafting/material item.
- Texture 9-slice untuk frame inventory final.
- SFX `inventory_open`, `inventory_close`, `item_use`, dan warning panic.
- Cursor/selection highlight khusus gamepad jika dukungan controller ditambahkan.

Untuk mobile, ikon item final sebaiknya memiliki silhouette sederhana dan kontras tinggi agar tetap terbaca pada ukuran kecil.
