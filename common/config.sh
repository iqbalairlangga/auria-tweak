#!/system/bin/sh
# Auria Tweak - user configuration
# Edit values and re-install for defaults, or edit on-device and reboot.

AURIA_LOG_ENABLE=1          # 1 = write /data/adb/auria_tweak.log

# --- Thermal policy ---
AURIA_THERMAL=1             # 1 = soften throttling, 2 = disable, 0 = stock

# --- Battery & charging ---
AURIA_CHARGING=1            # 1 = apply charging tweaks
AURIA_CHARGE_CURRENT=2000000  # uA fast-charge target (0 = leave stock)

# --- Display tuning ---
AURIA_DISPLAY=1             # 1 = apply display tweaks
AURIA_REFRESH=0             # HZ target (0/60/90/120); 0 = leave stock
AURIA_ANIMATION=1           # 1 = reduce animation scales

# --- Rendering & CPU/GPU ---
AURIA_RENDER=1              # 1 = GPU + renderer tweaks
AURIA_CPU_GOVERNOR=performance # scalable_ini preferred governor
AURIA_IO=1                  # 1 = IO scheduler & read-ahead
AURIA_VM=1                  # 1 = VM balancing (swappiness etc.)