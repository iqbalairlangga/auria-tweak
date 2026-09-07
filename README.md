# Auria Tweak

**Real tweak engine** untuk MediaTek Helio (G10–G200) dan Snapdragon (semua series).
Ringan, efisien, dan muat dalam 10MB — file ZIP hasil build hanya puluhan KB.

FLASH via Magisk / KernelSU / APatch, lalu **reboot**.

## Fitur

| Fitur | MediaTek | Snapdragon |
|-------|----------|------------|
| Thermal policy (soften/disable) | ✅ | ✅ |
| Battery & fast-charge | ✅ | ✅ |
| Display + refresh/animasi | ✅ | ✅ |
| Render (GPU + CPU) | ✅ | ✅ |
| IO scheduler & read-ahead | ✅ | ✅ |
| VM balancing | ✅ | ✅ |

## Konfigurasi

Semua bisa diatur di `common/config.sh` (edit setelah flash di
`/data/adb/modules/auria_tweak/common/config.sh`, lalu reboot):

```sh
AURIA_THERMAL=1        # 0=stock 1=soften 2=disable
AURIA_CHARGING=1
AURIA_CHARGE_CURRENT=2000000   # uA target
AURIA_DISPLAY=1
AURIA_REFRESH=0        # 0/60/90/120
AURIA_ANIMATION=1
AURIA_RENDER=1
AURIA_CPU_GOVERNOR=performance
AURIA_IO=1
AURIA_VM=1
AURIA_LOG_ENABLE=1
```

## Struktur

```
auria_tweak/       → instalasi otomatis ke module tree
├── module.prop      metadata
├── customize.sh     installer (deteksi SoC + status)
├── service.sh       boot service → memanggil engine
├── post-fs-data.sh  early VM tuning
├── system.prop      prop overlay
└── common/
    ├── config.sh    AURIA konfigurasi
    ├── helpers.sh   helper POSIX sh (write/prop/sysctl/SoC/gov)
    └── engine.sh    engine tweak modular per-fitur
```

## Build

```bash
./build_auria.sh     # butuh bash + zip; enforce ≤10MB
```

Auto-build & release via `.github/workflows/release.yml` setiap tag `v*`.

## Log

`/data/adb/auria_tweak.log` (aktif jika `AURIA_LOG_ENABLE=1`).