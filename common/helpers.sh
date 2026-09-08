#!/system/bin/sh
# Auria Tweak - shared helpers (POSIX sh)

AURIA_LOG="/data/adb/auria_tweak.log"
AURIA_VER="6.1.3"

a_log() {
    [ "$AURIA_LOG_ENABLE" = "1" ] || return 0
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$AURIA_LOG" 2>/dev/null
}

# Plain write to a node if it exists and is writable.
a_write() {
    [ -e "$2" ] || return 1
    [ -w "$2" ] || return 1
    echo "$1" > "$2" 2>/dev/null
}

# Write to the first applicable node among several candidates.
a_write_any() {
    local val="$1" p
    shift
    for p in "$@"; do
        [ -e "$p" ] || continue
        [ -w "$p" ] || continue
        echo "$val" > "$p" 2>/dev/null && return 0
    done
    return 1
}

# sysctl setter that skips unchanged values.
a_sysctl() {
    local key="$1" val="$2" cur
    cur=$(cat "/proc/sys/$key" 2>/dev/null) || return 1
    [ "$cur" = "$val" ] && return 0
    echo "$val" > "/proc/sys/$key" 2>/dev/null
}

# property setter that ignores empty values.
a_setprop() {
    [ -z "$2" ] && return 1
    setprop "$1" "$2" 2>/dev/null
}

# SoC family detection -> AURIA_SOC (mediatek|qualcomm|other).
detect_soc() {
    local hw bd
    hw=$(getprop ro.board.platform 2>/dev/null)
    bd=$(getprop ro.boot.hardware 2>/dev/null)
    case "$hw" in
        mt*)                              AURIA_SOC=mediatek ;;
        sm[0-9]*|sdm[0-9]*|msm[0-9]*|kona|lito|bengal|lahaina|taro|kalama|pineapple|parrot)
                                          AURIA_SOC=qualcomm ;;
        *)                                AURIA_SOC=other ;;
    esac
    [ "$AURIA_SOC" = "other" ] && {
        case "$bd" in
            mt*)                          AURIA_SOC=mediatek ;;
            qcom*)                        AURIA_SOC=qualcomm ;;
        esac
    }
    [ "$AURIA_SOC" = "other" ] && {
        [ -d /sys/kernel/ged/hal ] && AURIA_SOC=mediatek
        [ -d /sys/class/kgsl/kgsl-3d0/devfreq ] && AURIA_SOC=qualcomm
    }
}

# Boot/root manager detection -> AURIA_ROOT (magisk|ksu|apatch|other).
detect_root_mgr() {
    AURIA_ROOT=other
    if [ "$KSU" = "true" ] || [ -n "$KSU_VER_CODE" ] || [ -d /data/adb/ksu ]; then
        AURIA_ROOT=ksu
    elif [ "$APATCH" = "true" ] || [ -n "$APATCH_VER_CODE" ] || [ -d /data/adb/apd ] || [ -d /data/adb/APatch ]; then
        AURIA_ROOT=apatch
    elif [ -n "$MAGISK_VER_CODE" ] || [ -d /data/adb/magisk ]; then
        AURIA_ROOT=magisk
    fi
}

# Pick $1 as governor when available, otherwise fall through candidates.
set_governor() {
    local want="${1:-performance}" cpu dir gov cand
    for cpu in /sys/devices/system/cpu/cpu*; do
        dir="$cpu/cpufreq"
        [ -f "$dir/scaling_governor" ] || continue
        gov=""
        grep -qw "$want" "$dir/scaling_available_governors" 2>/dev/null && gov="$want" || {
            case "$want" in
                powersave)   for cand in schedutil ondemand interactive; do
                                 grep -qw "$cand" "$dir/scaling_available_governors" 2>/dev/null && { gov="$cand"; break; }
                             done ;;
                performance) for cand in schedutil ondemand interactive; do
                                 grep -qw "$cand" "$dir/scaling_available_governors" 2>/dev/null && { gov="$cand"; break; }
                             done ;;
                *)           for cand in schedutil ondemand interactive; do
                                 grep -qw "$cand" "$dir/scaling_available_governors" 2>/dev/null && { gov="$cand"; break; }
                             done ;;
            esac
        }
        [ -n "$gov" ] && echo "$gov" > "$dir/scaling_governor" 2>/dev/null
    done
}