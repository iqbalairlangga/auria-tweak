#!/system/bin/sh
# Auria Tweak - util functions
# Common helper functions for the module

# Logging
AURIA_LOG="/data/adb/auria_tweak.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AURIA_LOG"
}

# Write to sysfs safely
write_sysfs() {
    local path="$1"
    local value="$2"
    if [ -w "$path" ]; then
        echo "$value" > "$path" 2>/dev/null && log "SET $path = $value" || log "FAIL $path = $value"
    fi
}

# Try writing to a list of possible paths
write_any() {
    local value="$1"
    shift
    for path in "$@"; do
        if [ -w "$path" ]; then
            echo "$value" > "$path" 2>/dev/null && log "SET $path = $value" && return 0
        fi
    done
    log "NO_PATH for value=$value ($@)"
    return 1
}

# Check if a value exists in cpufreq available governors
set_governor() {
    local cpu="$1"
    local gov="$2"
    local avail="/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_available_governors"
    local target="/sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_governor"
    if [ -f "$avail" ] && grep -q "$gov" "$avail" 2>/dev/null; then
        write_sysfs "$target" "$gov"
    fi
}

is_mediatek() {
    [ "$(cat $MODDIR/soc_type.conf 2>/dev/null)" = "mediatek" ]
}

is_qualcomm() {
    [ "$(cat $MODDIR/soc_type.conf 2>/dev/null)" = "qualcomm" ]
}
