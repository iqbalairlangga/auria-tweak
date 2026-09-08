#!/system/bin/sh
# Auria Tweak - user configuration
# Edit here after flash: /data/adb/modules/auria_tweak/config.sh
# Profil bisa diganti tanpa reboot via WebUI / `sh cli.sh <profil>`.

AURIA_LOG_ENABLE=1

# ---------- Profiles ----------
# balanced | performance | powersave
AURIA_PROFILE=balanced

# ---------- (1) Thermal ----------
# 0=stock  1=soften throttling (recommended)
AURIA_THERMAL=1

# ---------- (2) Battery & Charging ----------
AURIA_CHARGING=1
AURIA_CHARGE_CURRENT=2000000   # uA fast-charge target (0 = leave stock)

# ---------- (3) Display / SurfaceFlinger ----------
AURIA_DISPLAY=1
AURIA_REFRESH=0                # 0/60/90/120
AURIA_ANIMATION=1

# ---------- (4) Rendering / GPU / CPU ----------
AURIA_RENDER=1
# Profile overrides governor; this is fallback for balanced
AURIA_CPU_GOVERNOR=performance

# ---------- (5) System Hygiene ----------
AURIA_IO=1
AURIA_VM=1