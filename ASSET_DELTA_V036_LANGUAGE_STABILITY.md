# Asset Delta — v0.36 Language Stability

Update ini hanya memperbaiki runtime localization dan UI language switching.

## Asset wajib baru

Tidak ada.

## Perubahan teknis yang memengaruhi UI

- Satu klik pada tombol bahasa sekarang hanya melakukan satu toggle.
- Localization HUD dinamis dijalankan setelah gameplay writer pada frame yang sama untuk menghilangkan EN/ID flicker.
- Full localization pass tidak lagi berjalan setiap 0.12 detik; hanya elemen volatile yang distabilkan per-frame, sedangkan static/world/journal pass berjalan lebih jarang untuk menjaga performa mobile.
- Desktop dan mobile memakai state bahasa yang sama.

## Asset opsional production

- Icon globe / language switch.
- Badge kecil ID / EN untuk mobile.
- Localized signage sebaiknya tetap memakai Label3D/runtime text, bukan tulisan yang dibakar ke texture, agar switching tidak memerlukan dua set texture.
