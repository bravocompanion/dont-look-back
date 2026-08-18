# Asset Delta — v0.32 HUD Layout

## Runtime change
- Health, Hunger, Thirst, Stamina, Battery, dan Darkness sekarang ditampilkan sebagai satu status bar horizontal di bagian atas.
- Panel stats vertikal lama disembunyikan.
- Objective, Case File, Shelter Status, Panic, Inventory, Controls, interaction tooltip, tombol Journal mobile, dan panel Journal diberi safe spacing responsif.
- Saat Journal terbuka, HUD gameplay disembunyikan agar note/mission text tidak tertutup elemen gameplay.
- Desktop dan mobile memakai layout berbeda tanpa mengubah gameplay stats.

## Aset wajib baru
Tidak ada aset baru yang wajib. Sistem v0.32 memakai Control/ProgressBar bawaan Godot sehingga dapat dites langsung setelah pull.

## Aset opsional untuk production polish
- 6 ikon HUD kecil: health, hunger/food, thirst/water, stamina, battery, darkness.
- 1 nine-slice panel texture untuk top status bar.
- 1 compact interaction prompt background.
- 1 journal/case-file panel texture yang tetap terbaca di layar mobile.
- Optional monochrome status icon atlas untuk mengurangi draw call mobile.

## Mobile/performance
- Tidak ada texture baru pada prototype sehingga biaya VRAM tambahan praktis nol.
- Top bar hanya terdiri dari Control, Label, dan ProgressBar.
- Untuk production, gabungkan ikon menjadi satu atlas kecil dan hindari efek blur/shader berat pada HUD mobile.
