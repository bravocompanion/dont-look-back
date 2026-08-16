# Asset Delta v0.24.3.1 — Panic Input Source Fix

Bugfix ini tidak membutuhkan asset baru.

## Asset baru wajib

Tidak ada.

## Asset yang tetap dipakai

- `music.*`
- `hurt.*`
- `monster.*`
- `baterai.mp3` sebagai flashlight/monster interference cue utama
- `tenant death.*` sebagai Tenant flashlight-kill confirmation
- existing Tenant prototype / production-model backlog
- existing flashlight model / first-person hand rig backlog

## QA yang dibutuhkan

Tidak ada art/audio baru, tetapi runtime test harus memastikan:

- PANIC tidak naik hanya karena monster dekat
- rapid Tenant flashlight flicker tetap bekerja
- `baterai.mp3` tetap dimainkan saat beam mengenai monster/Tenant
- `tenant death` tetap dimainkan satu kali setelah Tenant banish 3 detik
- desktop mouse dan mobile touch-look masih memberi PANIC ketika digerakkan cepat
- mobile joystick tidak salah dibaca sebagai look input

## Mobile / desktop

Tidak ada perubahan asset budget, texture, model, VFX, atau audio memory untuk v0.24.3.1.
