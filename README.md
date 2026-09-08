# Auria Tweak

**High-stability tuning engine** untuk MediaTek Helio (G10–G200) dan Snapdragon (semua series).
Ringan, efisien, dan muat dalam 10MB — file ZIP hasil build hanya ~14KB.

FLASH via **Magisk / KernelSU / APatch**, lalu **reboot** (setelah itu profil bisa
diganti kapan saja **tanpa reboot**).

> Hanya mendukung ketiga boot manager ini. Installer memverifikasi root manager;
> jika tidak terdeteksi Magisk/KernelSU/APatch, pemasangan akan dibatalkan.

## Fitur (gabungan dari AZenith + Project Raco)

| Fitur | Sumber | MediaTek | Snapdragon |
|-------|--------|----------|------------|
| Thermal policy (0/1/2) | AZenith + Kreapic | ✅ | ✅ |
| Thermal kill: stop HAL/engine + pin prop | Kreapic | ✅ | ✅ |
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
Ubah di `AURIA_PROFILE` pada config, atau langsung dari WebUI / CLI — profil
berlaku **tanpa reboot** (governor CPU + policy MTK/PPM/dvfsrc di-switch live).

```bash
# ganti profil dari terminal (berlaku langsung)
sh /data/adb/modules/auria_tweak/common/cli.sh performance
# pilihan: balanced | performance | powersave
```

## Konfigurasi

Edit `/data/adb/modules/auria_tweak/common/config.sh`. Profil berlaku
langsung; flag lainnya berlaku pada reboot berikutnya:

```sh
AURIA_PROFILE=balanced
AURIA_THERMAL=1            # 0=stock 1=soften 2=kill (stop thermal HAL)
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

## Install & Uninstall

**Install (disarankan):** flash ZIP `auria_tweak-vX.X.zip` via Magisk /
KernelSU / MMRL lalu reboot (memakai `customize.sh`).

**Install manual (terminal/ADB):** tanpa manager, jalankan sebagai root:

```bash
adb push auria_tweak-vX.X.zip /sdcard/Download/
adb shell "su -c 'unzip -o /sdcard/Download/auria_tweak-vX.X.zip -d /sdcard/Download/auria_tweak'"
adb shell "su -c 'sh /sdcard/Download/auria_tweak/install.sh'"
```

Update dengan cara yang sama; config user (`config.sh`) otomatis dibackup
(`config.sh.bak`) dan dipertahankan.

**Uninstall:** hapus module via manager (menjalankan `uninstall.sh`, restore
thermal/logger ke stock + bersihkan runtime), atau:

```bash
adb shell "su -c 'sh /data/adb/modules/auria_tweak/uninstall.sh'; ls /data/adb/modules"
```

## Stabilitas

- **Anti-bootloop:** dua boot gagal → modul auto-disable + petunjuk di description
- **Single-instance lock** untuk KernelSU metamodule (post-fs-data ganda)
- Semua write memakai guard `[ -e ]/[ -w ]`; tidak ada abort pada node hilang
- Loop berjalan di background (`apply_tweaks &`) agar UI tetap responsif

## WebUI

Buka lewat tombol **WebUI** di KernelSU Manager (Next) atau aplikasi MMRL
(untuk Magisk/KernelSU). Tampilan terinspirasi dashboard AZenith dan tema
Project Raco.

| Kontrol | Efek |
|---------|------|
| Ketuk profil (Balanced/Performance/Powersave) | ganti `AURIA_PROFILE` + **terapkan langsung, tanpa reboot** |
| Toggle per fitur | set flag di `config.sh` |
| Fitur Lanjutan (SF latency, FPSGO, WALT, Kill logd) | kartu khusus bertanda risiko; ON = terapkan, OFF = **dipulihkan ke bawaan tanpa reboot** |
| Thermal (Stock/Soft/Kill) | segment control; Kill = matikan thermal engine (bisa kembali ke Stock) |
| `Terapkan Sekarang` | tulis config & jalankan engine langsung dengan profil aktif |
| `Simpan & Reboot` | tulis config lalu reboot |

Profil diganti tanpa reboot: klik kartu profil → WebUI menulis `AURIA_PROFILE`
ke `config.sh` lalu memanggil `common/cli.sh <profil>`; engine mengubah governor
CPU serta policy MTK/PPM/dvfsrc sesuai profil secara runtime (tanpa restart).

WebUI membaca/menulis `common/config.sh` dan bisa memanggil `common/cli.sh`
untuk menerapkan tanpa reboot. Butuh KernelSU Manager untuk bridge shell
(`window.kuband`); di browser biasa hanya tampil status (read-only).

## Struktur

```
auria_tweak/       → instalasi otomatis ke module tree
├── module.prop      metadata
├── customize.sh     installer zip (manager): deteksi SoC + baseline anti-bootloop
├── install.sh       installer mandiri (terminal/ADB), pertahankan config user
├── uninstall.sh     uninstaller: restore thermal/logger ke stock + cleanup runtime
├── service.sh       boot service: reset counter, lalu jalankan engine
├── post-fs-data.sh  guard single-instance + anti-bootloop counter
├── system.prop      prop overlay (aman/persisten)
├── webroot/
│   └── index.html   WebUI (KernelSU/MMRL bridge)
└── common/
    ├── config.sh    AURIA konfigurasi
    ├── helpers.sh   helper POSIX sh (write/lock/prop/sysctl/SoC/gov)
    ├── engine.sh    engine per-fitur (thermal→charging→display→render→io/vm)
    └── cli.sh       ganti profil & apply tanpa reboot (WebUI/terminal)
```

## Build

```bash
./build_auria.sh     # butuh bash + zip; enforce ≤10MB
```

Auto-build & release via `.github/workflows/release.yml` setiap tag `v*`.

## Log

`/data/adb/auria_tweak.log` (aktif jika `AURIA_LOG_ENABLE=1`).

## Changelog

- **v5.7** — kunci modul ke **Magisk / KernelSU / APatch** saja: installer
  (customize.sh + install.sh) memverifikasi root manager, tolak bila lain.
- **v5.6** — tambah `install.sh`: installer mandiri untuk terminal/ADB tanpa
  manager; backup `config.sh` user saat update dan pertahankan pengaturannya.
- **v5.5** — tambah `uninstall.sh`: restore thermal/logger ke stock + bersihkan
  runtime (log, snapshot policy, config backup); installer juga sudah ada (`customize.sh`).
- **v5.4** — Thermal kill diperkuat metode **Kreapic-Disable-Thermal**: stop
  semua service thermal HAL/engine (18 service, dedup), kunci `init.svc.*=stopped`,
  knob `msm_thermal core_control`, & restore service saat kembali ke Stock.
- **v5.3** — semua fitur lanjutan (SF latency, FPSGO, WALT, kill logd, thermal kill)
  bisa di-ON/OFF langsung dari WebUI; OFF memulihkan ke bawaan tanpa reboot
  (thermal policy disnapshot untuk restore akurat); kartu "Fitur Lanjutan" khusus.
- **v5.2** — ganti profil tanpa reboot (WebUI / `cli.sh`); governor CPU mengikuti
  profil aktif; fallback governor profile-aware; tombol "Terapkan Sekarang".
- **v5.1** — WebUI baru (KernelSU/MMRL), gaya AZenith + Raco; CLI apply; deteksi SoC.
- **v5.0** — engine modular merge AZenith + Raco (establish baseline).
- **v4.0** — engine bersih & modular, ≤10MB.
- **v3.7** — rilis stabil awal.

## Kredit

- **AZenith** — Zexshia (Liliya2727) & ArchHaven, Apache-2.0
- **Project Raco** — Kanagawa Yamada
- **Kreapic-Disable-Thermal** — mahisataruna x AlgorithmIDN (teknik disable thermal universal)
Video & teknik diadaptasi dan disederhanakan demi stabilitas.