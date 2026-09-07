# Auria Tweak

**Performance & Battery Optimizer** untuk perangkat MediaTek Helio (G10 - G200) dan Snapdragon (semua series).

## Fitur

| Fitur | MediaTek Helio | Snapdragon |
|--------|----------------|------------|
| ✅ Disable Thermal | ✅ | ✅ |
| ✅ Optimasi Charging | ✅ | ✅ |
| ✅ Optimasi Layar | ✅ | ✅ |
| ✅ Optimasi Rendering | ✅ | ✅ |

## Dukungan SoC

### MediaTek Helio Series
- **G Series**: G10, G25, G35, G36, G37, G50, G51, G70, G75, G80, G81, G85, G88, G90, G91, G95, G96, G99, G100, G200
- **MTK Generic**: MT6761, MT6762, MT6765, MT6768, MT6769, MT6771, MT6781, MT6785, MT6833, MT6853, MT6873, MT6877, MT6885, MT6893

### Snapdragon Series
- **400 Series**: 425, 429, 435, 439, 450, 460, 480, 662, 665
- **600 Series**: 625, 630, 632, 636, 660, 662, 665, 670, 675, 678, 680, 685, 685 5G, 690, 695, 7s Gen 2
- **700 Series**: 710, 712, 720G, 730, 730G, 732G, 750G, 765G, 778G, 782G, 7 Gen 1, 7s Gen 2
- **800 Series**: 821, 835, 845, 855, 860, 865, 870, 888, 888+, 8 Gen 1, 8+ Gen 1, 8 Gen 2, 8 Gen 3
- **MSM/SM series**: msm8916 → sm8650 (semua seri)

## Cara Pakai

1. Download file `.zip` dari **Release**
2. Flashing via **Magisk Manager** / **KernelSU** / **APatch**
3. Reboot

## Fitur Detail

### 🔥 Disable Thermal
- Menonaktifkan thermal throttling untuk performa maksimal
- Otomatis deteksi SoC (MediaTek / Qualcomm)

### 🔋 Optimasi Charging
- Mempercepat proses charging
- Mengoptimalkan arus/voltase pengisian

### 📱 Optimasi Layar
- Gambar lebih jernih
- Menyesuaikan refresh rate (60/90/120Hz)

### 🎨 Optimasi Rendering
- GPU boost (Mali / Adreno)
- Renderer GPU untuk UI lebih mulus
- Animasi dipercepat

## Struktur Modul

```
auria-tweak/
├── module.prop          # Metadata modul
├── customize.sh         # Installer script
├── service.sh           # Runtime script (boot)
├── post-fs-data.sh      # Early boot script
├── common/
│   ├── util_functions.sh  # Helper function
│   └── auria_tweak.sh     # Main tweak engine
└── system/              # System file overlay (opsional)
```

## Build Manual

```bash
# Jalankan build script untuk membuat zip
./build_auria.sh
```

Atau build otomatis via **GitHub Actions** (CI/CD).

## Lisensi
MIT License © AuriaDev