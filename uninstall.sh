#!/system/bin/sh
# Auria Tweak - uninstaller
# Restores thermal/kernel state to stock and removes runtime artifacts
# (log, thermal policy snapshot, single-instance lock).

MODDIR=${0%/*}

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

ui_print "- Auria Tweak cleanup..."

. "$MODDIR/common/helpers.sh"

# Restore MTK zone policies snapshotted before userspace override.
if [ -f /data/adb/auria_thermal_policy.bak ]; then
    while read -r zone policy; do
        [ -n "$zone" ] && [ -n "$policy" ] && a_write "$policy" "$zone/policy"
    done < /data/adb/auria_thermal_policy.bak
    rm -f /data/adb/auria_thermal_policy.bak
fi

# Re-enable thermal kernel knobs and zones.
a_write "1" /sys/module/thermal/parameters/enabled
a_write "1" /proc/cpufreq/cpufreq_imax_enable
for z in /sys/class/thermal/thermal_zone*/mode; do a_write enabled "$z"; done
a_write_any "1" /sys/module/msm_thermal/parameters/enabled \
    /sys/module/msm_thermal/parameters/therm_limit_disable
a_write "1" /sys/module/msm_thermal/parameters/vdd_restriction_enabled
a_write "1" /sys/module/msm_thermal/core_control/enabled
a_write "1" /sys/kernel/msm_thermal/enabled

# Restart thermal HAL/engine services (Kreapic list).
for svc in \
    android.thermal-hal vendor.thermal-engine vendor.thermal_manager \
    vendor.thermal-manager vendor.thermal-hal-2-0 vendor.thermal-hal-1-0 \
    vendor-thermal-1-0 vendor.thermal-symlinks thermal_mnt_hal_service \
    thermal thermal-engine thermald thermalloadalgod thermalservice \
    sec-thermal-1-0 debug_pid.sec-thermal-1-0 thermal-hal mi_thermald
do
    start "$svc" 2>/dev/null
done

# Restart loggers we may have stopped.
for logger in logd traced statsd tcpdump cnss_diag subsystem_ramdump charge_logger wlan_logging; do
    start "$logger" 2>/dev/null
done

# Drop runtime artifacts.
rm -f /data/adb/auria_tweak.log 2>/dev/null
rm -f /data/adb/auria_tweak/config.sh.bak 2>/dev/null
rm -f /dev/.auria_tweak_single 2>/dev/null

ui_print "- Auria Tweak removed. Reboot to fully restore state."
exit 0