# Auria Tweak v6.0

**Clean & stable tuning engine** untuk MediaTek Helio (G10–G200) dan Snapdragon (semua series).
Ringan, efisien, dan muat dalam 10MB — file ZIP hasil build hanya ~14KB.

FLASH via **Magisk / KernelSU / APatch**, lalu **reboot**.

> Hanya mendukung ketiga boot manager ini. Installer memverifikasi root manager;
> jika tidak terdeteksi Magisk/KernelSU/APatch, pemasangan dibatalkan.

## Fitur (Clean & Stable)

| Fitur | MediaTek | Snapdragon |
|-------|----------|------------|
| Thermal soften (mode 1) | ✅ | ✅ |
| Battery & charging | ✅ | ✅ |
| Display / SF tuning (Zeta props) | ✅ | ✅ |
| Render / GPU / CPU governor | ✅ | ✅ |
| IO scheduler (mq-deadline) | ✅ | ✅ |
| VM balance | ✅ | ✅ |
| MTK PPM & dvfsrc | ✅ | – |
| Anti-bootloop self-heal | ✅ | ✅ |
| Single-instance guard (KSU) | ✅ | ✅ |

**Tidak ada fitur risiko:** FPSGO, WALT, SF latency, thermal kill, kill logd — semua dibuang.

## Profil

`balanced` (default) · `performance` · `powersave`
Ubah via WebUI / CLI — **berlaku tanpa reboot** (governor CPU di-switch live).

```bash
sh /data/adb/modules/auria_tweak/common/cli.sh performance
# pilihan: balanced | performance | powersave
```

## Konfigurasi

Edit `/data/adb/modules/auria_tweak/common/config.sh`. Profil berlaku
langsung; flag lain berlaku pada reboot berikutnya:

```sh
AURIA_PROFILE=balanced
AURIA_THERMAL=1            # 0=stock 1=soften (recommended)
AURIA_CHARGING=1
AURIA_CHARGE_CURRENT=2000000
AURIA_DISPLAY=1
AURIA_REFRESH=0            # 0/60/90/120
AURIA_ANIMATION=1
AURIA_RENDER=1
AURIA_CPU_GOVERNOR=performance
AURIA_IO=1
AURIA_VM=1
AURIA_LOG_ENABLE=1
```

## Stabilitas

- **Anti-bootloop:** dua boot gagal → modul auto-disable + petunjuk di description
- **Single-instance lock** untuk KernelSU metamodule (post-fs-data ganda)
- Semua write memakai guard `[ -e ]/[ -w ]`; tidak ada abort pada node hilang
- Loop berjalan di background (`apply_tweaks &`) agar UI tetap responsif

## WebUI

Buka lewat tombol **WebUI** di KernelSU Manager (Next) atau aplikasi MMRL.

| Kontrol | Efek |
|---------|------|
| Ketuk profil | ganti `AURIA_PROFILE` + terapkan langsung tanpa reboot |
| Toggle per fitur | set flag di `config.sh` |
| `Terapkan Sekarang` | tulis config & jalankan engine langsung dengan profil aktif |
| `Simpan & Reboot` | tulis config lalu reboot |

WebUI butuh KernelSU Manager untuk bridge shell (`window.kuband`); di browser biasa hanya read-only.

## Struktur

```
auria_tweak/
├── module.prop        metadata
├── customize.sh       installer (manager): deteksi SoC + baseline anti-bootloop
├── install.sh         installer manual (ADB/terminal), backup config user
├── uninstall.sh       uninstaller: restore thermal/logger ke stock + cleanup runtime
├── service.sh         boot service: reset counter, lalu jalankan engine
├── post-fs-data.sh    guard single-instance + anti-bootloop counter
├── system.prop        prop overlay (aman/persisten)
├── webroot/
│   └── index.html     WebUI (KernelSU/MMRL bridge)
└── common/
    ├── config.sh      AURIA konfigurasi (12 opsi)
    ├── helpers.sh     helper POSIX sh (write/lock/prop/sysctl/SoC/gov/root-detect)
    ├── engine.sh      engine per-fitur (thermal→charging→display→render→io/vm)
    └── cli.sh         apply-on-demand (WebUI "Terapkan Sekarang")
```

## Build

```bash
./build_auria.sh     # butuh bash + zip; enforce ≤10MB
```

Auto-build & release via `.github/workflows/release.yml` setiap tag `v*`.

## Log

`/data/adb/auria_tweak.log` (aktif jika `AURIA_LOG_ENABLE=1`).

## Changelog

- **v6.0** — **Total cleanup**: hapus FPSGO, WALT, SF latency, thermal kill (18 services), kill logd, sf_color, zeta props berlebih, restore logic kompleks. Simpan hanya tweak stabil & terbukti. Engine ~180 baris (dari 404). Config 12 opsi (dari 38). WebUI bersih.
- **v5.7** — kunci modul ke Magisk / KernelSU / APatch saja.
- **v5.6** — tambah `install.sh` installer mandiri.
- **v5.5** — tambah `uninstall.sh` restore thermal/logger.
- **v5.4** — thermal kill metode Kreapic (dibuang v6.0).
- **v5.3** — fitur lanjutan ON/OFF dua arah.
- **v5.2** — ganti profil tanpa reboot.
- **v5.1** — WebUI baru (KernelSU/MMRL).
- **v5.0** — engine modular merge AZenith + Raco.
- **v4.0** — engine bersih & modular, ≤10MB.
- **v3.7** — rilis stabil awal.

## Kredit

- **AZenith** — Zexshia (Liliya2727) & ArchHaven, Apache-2.0
- **Project Raco** — Kanagawa Yamada
Video & teknik diadaptasi dan disederhanakan demi stabilitas.