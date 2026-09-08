#!/system/bin/sh
# Auria Tweak - user configuration
# Edit here after flash: /data/adb/modules/auria_tweak/common/config.sh
# Profil bisa diganti tanpa reboot via WebUI "Terapkan" / `sh cli.sh <profil>`.
# Nilai lain berlaku pada boot berikutnya.

AURIA_LOG_ENABLE=1

# ---------- Profiles ----------
# balanced | performance | powersave
AURIA_PROFILE=balanced

# ---------- (1) Thermal policy ----------
# 0=stock  1=soften throttling  2=aggressive (kill thermal engine)
AURIA_THERMAL=1

# ---------- (2) Battery & charging ----------
AURIA_CHARGING=1
AURIA_CHARGE_CURRENT=2000000   # uA fast-charge target (0 = leave stock)

# ---------- (3) Display / SurfaceFlinger ----------
AURIA_DISPLAY=1
# SF latency draw (dynamic phase offsets). Advanced, default off.
AURIA_SF_LATENCY=0
AURIA_REFRESH=0                # 0/60/90/120
AURIA_ANIMATION=1

# ---------- (4) Rendering / GPU / CPU ----------
AURIA_RENDER=1
AURIA_CPU_GOVERNOR=performance # preferred scaling governor
AURIA_MTK_FPSGO=0              # MTK fpsgo/GED heavy boost (default off)
AURIA_MTK_PPM=1                # MTK PPM policy parser
AURIA_WALT=0                   # MTK walt governor tuning (default off)

# ---------- (5) Misc system hygiene ----------
AURIA_IO=1
AURIA_VM=1
AURIA_KILL_LOGD=0              # stop logd/statsd etc on boot (default off)