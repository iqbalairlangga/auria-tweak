#!/system/bin/sh
# Auria Tweak - shared helpers (POSIX sh)

AURIA_LOG="/data/adb/auria_tweak.log"
AURIA_VER="4.0"

a_log() {
    [ "$AURIA_LOG_ENABLE" = "1" ] || return 0
    echo "[$(date '+%m-%d %H:%M:%S')] $1" >> "$AURIA_LOG" 2>/dev/null
}

# Write value to a single node if writable.
a_write() {
    [ -w "$2" ] && echo "$1" > "$2" 2>/dev/null
}

# Write value to the first writable node among candidates.
a_write_any() {
    local val="$1" p
    shift
    for p in "$@"; do
        if [ -w "$p" ]; then
            echo "$val" > "$p" 2>/dev/null && return 0
        fi
    done
    return 1
}

# Set a sysctl value if the key exists and differs.
a_sysctl() {
    local key="$1" val="$2" cur
    cur=$(cat "/proc/sys/$key" 2>/dev/null) || return 1
    [ "$cur" = "$val" ] && return 0
    echo "$val" > "/proc/sys/$key" 2>/dev/null
}

# Set a property only if value is non-empty.
a_setprop() {
    [ -z "$2" ] && return 1
    setprop "$1" "$2" 2>/dev/null
}

# Detect SoC family -> AURIA_SOC (mediatek|qualcomm|other).
detect_soc() {
    local hw bd
    hw=$(getprop ro.board.platform 2>/dev/null)
    bd=$(getprop ro.boot.hardware 2>/dev/null)
    case "$hw" in
        mt*) AURIA_SOC=mediatek ;;
        sm[0-9]*|sdm[0-9]*|msm[0-9]*|kona|lito|bengal|lahaina|taro|kalama|pineapple)
            AURIA_SOC=qualcomm ;;
        *)
            case "$bd" in
                mt*)   AURIA_SOC=mediatek ;;
                qcom*) AURIA_SOC=qualcomm ;;
                *)     AURIA_SOC=other ;;
            esac
            ;;
    esac
}

# Prefer $1 if available, else pick the first governor present.
set_best_governor() {
    local want="${1:-performance}" cpu gov found
    for cpu in /sys/devices/system/cpu/cpu*; do
        dir="$cpu/cpufreq"
        [ -f "$dir/scaling_governor" ] || continue
        gov=""
        if [ -f "$dir/scaling_available_governors" ] && \
            grep -qw "$want" "$dir/scaling_available_governors" 2>/dev/null; then
            gov="$want"
        elif [ -f "$dir/scaling_available_governors" ]; then
            for cand in performance schedutil ondemand; do
                if grep -qw "$cand" "$dir/scaling_available_governors" 2>/dev/null; then
                    gov="$cand"; break
                fi
            done
        fi
        [ -n "$gov" ] && echo "$gov" > "$dir/scaling_governor" 2>/dev/null
    done
}