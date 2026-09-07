# Auria Tweak

**High-stability tuning engine** untuk MediaTek Helio (G10–G200) dan Snapdragon (semua series).
Ringan, efisien, dan muat dalam 10MB — file ZIP hasil build hanya ~8KB.

FLASH via Magisk / KernelSU / APatch, lalu **reboot**.

## Fitur (gabungan dari AZenith + Project Raco)

| Fitur | Sumber | MediaTek | Snapdragon |
|-------|--------|----------|------------|
| Thermal policy (0/1/2) | AZenith | ✅ | ✅ |
| MTK PPM policy parser | AZenith | ✅ | – |
| MTK dvfsrc/bus tuning | AZenith | ✅ | – |
| QC bus devfreq + kgsl | AZenith | – | ✅ |
| MTK Mali power policy | AZenith | ✅ | – |
| MTK fpsgo/GED (opsional) | AZenith | ✅ | – |
| MTK walt governor (ops.) | AZenith | ✅ | – |
| SF phase-offset latency (ops.) | AZenith | ✅ | ✅ |
| Zeta props + SF color | Raco | ✅ | ✅ |
| Charging / battery | — | ✅ | ✅ |
| Display / refresh / animasi | — | ✅ | ✅ |
| IO scheduler & read-ahead | — | ✅ | ✅ |
| VM balancing | — | ✅ | ✅ |
| Anti-bootloop self-heal | AZenith | ✅ | ✅ |
| Single-instance guard (KSU) | AZenith | ✅ | ✅ |

Semua fitur lanjutan (SF latency, WALT, fpsgo, kill logd, thermal=kill)
default **OFF** demi stabilitas; aktifkan di config bila paham risikonya.

## Profil

`balanced` (default) · `performance` · `powersave`
Ubah di `AURIA_PROFILE` pada config, lalu reboot.

## Konfigurasi

Edit `/data/adb/modules/auria_tweak/common/config.sh`, lalu reboot:

```sh
AURIA_PROFILE=balanced
AURIA_THERMAL=1            # 0=stock 1=soften 2=kill
AURIA_CHARGING=1
AURIA_CHARGE_CURRENT=2000000
AURIA_DISPLAY=1
AURIA_SF_LATENCY=0         # advanced, default off
AURIA_REFRESH=0            # 0/60/90/120
AURIA_ANIMATION=1
AURIA_RENDER=1
AURIA_CPU_GOVERNOR=performance
AURIA_MTK_FPSGO=0          # default off
AURIA_MTK_PPM=1
AURIA_WALT=0               # default off
AURIA_IO=1
AURIA_VM=1
AURIA_KILL_LOGD=0          # default off
AURIA_LOG_ENABLE=1
```

## Stabilitas

- **Anti-bootloop:** dua boot gagal → modul auto-disable + petunjuk di description
- **Single-instance lock** untuk KernelSU metamodule (post-fs-data ganda)
- Semua write memakai guard `[ -e ]/[ -w ]`; tidak ada abort pada node hilang
- Loop berjalan di background (`apply_tweaks &`) agar UI tetap responsif

## Struktur

```
auria_tweak/       → instalasi otomatis ke module tree
├── module.prop      metadata
├── customize.sh     installer: deteksi SoC robust + baseline anti-bootloop
├── service.sh       boot service: reset counter, lalu jalankan engine
├── post-fs-data.sh  guard single-instance + anti-bootloop counter
├── system.prop      prop overlay (aman/persisten)
└── common/
    ├── config.sh    AURIA konfigurasi
    ├── helpers.sh   helper POSIX sh (write/lock/prop/sysctl/SoC/gov)
    └── engine.sh    engine per-fitur (thermal→charging→display→render→io/vm)
```

## Build

```bash
./build_auria.sh     # butuh bash + zip; enforce ≤10MB
```

Auto-build & release via `.github/workflows/release.yml` setiap tag `v*`.

## Log

`/data/adb/auria_tweak.log` (aktif jika `AURIA_LOG_ENABLE=1`).

## Kredit

- **AZenith** — Zexshia (Liliya2727) & ArchHaven, Apache-2.0
- **Project Raco** — Kanagawa Yamada
Video & teknik diadaptasi dan disederhanakan demi stabilitas.