# Asset Delta — Forest Mega Map

## Update layout

Forest sekarang ditargetkan sekitar 224 m x 304 m (sekitar 68.096 m²), kira-kira 4x area playable forest sebelumnya.

Mission clusters dipisahkan jauh:
- Ranger Cabin / Base: sekitar (14, -82)
- Abandoned House: sekitar (-70, -155)
- Old Gas Station: sekitar (76, -225)
- Warehouse: sekitar (-72, -286)
- Old Water Pump / far expedition: sekitar (62, -332)

Boundary fisik map tetap ada tetapi tidak memiliki visual.

## P0 — dibutuhkan untuk mengganti blockout

- Modular forest ground materials: dirt, mud, moss, gravel, wet variants.
- Pine / fir / dead-tree set dengan LOD0/LOD1/LOD2 dan billboard/impostor untuk mobile.
- Bush, fern, grass, fallen branch dan rock scatter set dengan LOD.
- Trail/path decal atau mesh set untuk menghubungkan lokasi yang berjauhan.
- Ranger Cabin production exterior + interior.
- Abandoned House production kit.
- Old Gas Station production kit + pumps/canopy/store props.
- Warehouse production kit + shelf/crate/scrap props.
- Water pump / creek / pond props.
- Mission signage / trail marker / ranger marker set.

## P1 — ambience dan navigasi

- Forest wind loops (light/heavy/storm).
- Distant owl/bird/insect layers untuk siang dan malam.
- Branch snap / distant movement one-shots.
- Dirt, mud, grass, gravel, wood footstep SFX.
- Fog cards / low mist meshes yang murah untuk mobile.
- Distant landmark silhouettes agar pemain dapat orientasi tanpa minimap penuh.
- Reflective trail marker / ranger ribbon props.

## Lighting target

- Natural object readability sekitar 10–15% melalui ambient floor + low-energy directional fill.
- Fill tidak memakai permanent OmniLight agar tidak mematikan Darkness Creature gameplay.
- Daylight gameplay protection boleh map-wide pada siang hari dan harus mati saat dusk/night.
- Mission practical lights tetap lokal: porch lamp, gas emergency light, warehouse lamp, lantern/camp light.

## Performance target

- Vegetation jauh harus memakai MultiMesh/LOD, bukan ratusan StaticBody individual.
- Collision hanya diberikan ke pohon/rock yang benar-benar mempengaruhi gameplay.
- Mobile target memakai density vegetation lebih rendah dan shadow distance lebih pendek.
- Desktop dapat memakai density/LOD distance lebih tinggi tanpa mengubah layout gameplay.
