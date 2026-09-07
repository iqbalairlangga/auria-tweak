#!/system/bin/sh
# Auria Tweak - post-fs-data.sh
# Executed in post-fs-data mode (early boot)

MODDIR=${0%/*}
SOCRACE=$(cat "$MODDIR/soc_type.conf" 2>/dev/null)

# Initialize log
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auria Tweak post-fs-data (SOC: $SOCRACE)" > /data/adb/auria_tweak.log 2>/dev/null

# Early thermal disabling attempt
write_any() {
    local value="$1"
    shift
    for path in "$@"; do
        if [ -w "$path" ]; then
            echo "$value" > "$path" 2>/dev/null
            return 0
        fi
    done
    return 1
}

write_any "0" /sys/module/msm_thermal/parameters/enabled
write_any "0" /sys/module/msm_thermal/parameters/vdd_restriction_enabled
write_any "0" /sys/module/thermal/parameters/thermal_limit_disable

exit 0
