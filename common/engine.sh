#!/system/bin/sh
# Auria Tweak - main engine
# Merge of proven tweaks from AZenith and Project Raco, tuned for stability.
# Loaded by service.sh with helpers + config sourced.

L() { a_log "$1"; }

# ===================================================================
# (1) THERMAL
# ===================================================================

# MTK: parse PPM policy_status and lift clamp policies like AZenith.
mtk_ppm_policy() {
    [ "$AURIA_MTK_PPM" = "1" ] || return 0
    [ -f /proc/ppm/policy_status ] || return 0
    local mode="$1" idx
    # performance: 0 = release clamps ; balanced/powersave: keep 1
    local clamp=1
    [ "$mode" = "performance" ] && clamp=0
    awk -F'[][]' '/FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT/{print $2}' /proc/ppm/policy_status 2>/dev/null | while read -r idx; do
        [ -n "$idx" ] && echo "$idx $clamp" > /proc/ppm/policy_status 2>/dev/null
    done
}

# MTK: dvfsrc responders - follow profile.
mtk_dvfsrc() {
    local mode="$1" gov="-1" opp="-1"
    case "$mode" in
        performance) gov="performance"; opp="0" ;;
        powersave)   gov="powersave" ;;
    esac
    a_write "$opp" /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp
    a_write "$gov" /sys/class/devfreq/mtk-dvfsrc-devfreq/governor
    for d in /sys/devices/platform/*.dvfsrc; do
        [ -e "$d/helio-dvfsrc/dvfsrc_req_ddr_opp" ] && echo "$opp" > "$d/helio-dvfsrc/dvfsrc_req_ddr_opp" 2>/dev/null
    done
    for d in /sys/devices/platform/soc/*.dvfsrc; do
        [ -e "$d/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor" ] && \
            echo "$gov" > "$d/mtk-dvfsrc-devfreq/devfreq/mtk-dvfsrc-devfreq/governor" 2>/dev/null
    done
}

set_thermal() {
    [ "$AURIA_THERMAL" = "0" ] && return 0
    case "$AURIA_SOC" in
        mediatek)
            case "$AURIA_THERMAL" in
                1)
                    a_write "0" /sys/module/thermal/parameters/enabled
                    a_write "0" /proc/cpufreq/cpufreq_imax_enable
                    L "MTK thermal: soften"
                    ;;
                2)
                    a_write "0" /sys/module/thermal/parameters/enabled
                    for z in /sys/class/thermal/thermal_zone*/mode; do a_write disabled "$z"; done
                    for z in /sys/class/thermal/thermal_zone*/policy; do a_write userspace "$z"; done
                    L "MTK thermal: kill"
                    ;;
            esac
            ;;
        qualcomm)
            case "$AURIA_THERMAL" in
                1)
                    a_write_any "0" /sys/module/msm_thermal/parameters/enabled \
                        /sys/module/msm_thermal/parameters/therm_limit_disable
                    L "QC thermal: soften"
                    ;;
                2)
                    a_write_any "0" /sys/module/msm_thermal/parameters/enabled \
                        /sys/module/msm_thermal/parameters/vdd_restriction_enabled
                    for z in /sys/class/thermal/thermal_zone*/mode; do a_write disabled "$z"; done
                    L "QC thermal: kill"
                    ;;
            esac
            ;;
    esac
}

# ===================================================================
# (2) BATTERY / CHARGING
# ===================================================================

set_charging() {
    [ "$AURIA_CHARGING" = "1" ] || return 0
    a_write "1" /sys/class/power_supply/battery/charging_enabled
    a_write "1" /sys/module/qpnp_smbcharger/parameters/smbchg_charger_enabled
    if [ "$AURIA_CHARGE_CURRENT" -gt 0 ]; then
        a_write_any "$AURIA_CHARGE_CURRENT" \
            /sys/class/power_supply/battery/constant_charge_current_max \
            /sys/class/power_supply/main/current_max \
            /sys/class/power_supply/usb/current_max
    fi
    L "charging: current=${AURIA_CHARGE_CURRENT}"
}

# ===================================================================
# (3) DISPLAY / SURFACEFLINGER
# ===================================================================

# Zeta props merged from Project Raco (surface_flinger & gralloc).
zeta_sf_props() {
    resetprop debug.sf.disable_backpressure 1 2>/dev/null
    resetprop debug.sf.disable_hwc 1 2>/dev/null
    resetprop debug.sf.latch_unsignaled 1 2>/dev/null
    resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3 2>/dev/null
    resetprop debug.gralloc.enable_fb_ubwc 0 2>/dev/null
    resetprop ro.max.fling_velocity 10000 2>/dev/null
}

# SurfaceFlinger color matrix / saturation (from Raco AyundaRusdi).
sf_color() {
    service call SurfaceFlinger 1015 i32 1 f 1.0 f 0 f 0 f 0 f 0 f 1.0 f 0 f 0 f 0 f 0 f 1.0 f 0 f 0 f 0 f 0 f 1 2>/dev/null
    service call SurfaceFlinger 1022 f 1.0 2>/dev/null
}

# Advanced SF phase-offset tuning (AZenith). Conservative defaults.
set_sf_latency() {
    [ "$AURIA_SF_LATENCY" = "1" ] || return 0
    local period rate ns
    period=$(dumpsys SurfaceFlinger --latency 2>/dev/null | head -n1 | awk '{print $1}')
    case "$period" in
        ''|*[!0-9]*) return 0 ;;
    esac
    [ "$period" -gt 0 ] || return 0
    rate=$(((1000000000 + period / 2) / period))
    [ "$rate" -ge 30 ] && [ "$rate" -le 240 ] || return 0
    ns=$(awk -v r="$rate" 'BEGIN { printf "%.0f", 1000000000 / r }')
    resetprop -n debug.sf.early.sf.duration "$(awk -v n="$ns" 'BEGIN{printf "%.0f", n*0.32}')" 2>/dev/null
    resetprop -n debug.sf.early.app.duration "$(awk -v n="$ns" 'BEGIN{printf "%.0f", n*0.58}')" 2>/dev/null
    resetprop -n debug.sf.late.sf.duration "$(awk -v n="$ns" 'BEGIN{printf "%.0f", n*0.32}')" 2>/dev/null
    resetprop -n debug.sf.late.app.duration "$(awk -v n="$ns" 'BEGIN{printf "%.0f", n*0.58}')" 2>/dev/null
    resetprop -n debug.sf.enable_advanced_sf_phase_offset 1 2>/dev/null
    L "SF latency: ${rate}Hz"
}

set_display() {
    [ "$AURIA_DISPLAY" = "1" ] || return 0
    zeta_sf_props
    set_sf_latency
    case "$AURIA_REFRESH" in
        60|90|120)
            setprop persist.vendor.peak_refresh_rate "$AURIA_REFRESH" 2>/dev/null
            setprop video.peak.refresh.rate "$AURIA_REFRESH" 2>/dev/null
            ;;
    esac
    sf_color
    if [ "$AURIA_ANIMATION" = "1" ]; then
        for kw in window_animation_scale transition_animation_scale animator_duration_scale; do
            cmd settings put global "$kw" 0.5 2>/dev/null &
        done
    fi
    L "display: applied"
}

# ===================================================================
# (4) RENDERING / GPU / CPU
# ===================================================================

# QC: bus devfreq governors + kgsl GPU (from AZenith snapdragon.rs).
set_render_qc() {
    local gov="$1" d
    a_write_any "$gov" /sys/class/kgsl/kgsl-3d0/devfreq/governor
    a_write "3" /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost 2>/dev/null || \
        a_write "1" /sys/class/kgsl/kgsl-3d0/devfreq/adrenoboost 2>/dev/null
    for d in /sys/class/devfreq/*cpu-ddr-latfloor* /sys/class/devfreq/*cpu*-lat \
        /sys/class/devfreq/*cpu-cpu-ddr-bw /sys/class/devfreq/*cpu-cpu-llcc-bw \
        /sys/class/devfreq/*gpubw*; do
        [ -e "$d/governor" ] && echo "$gov" > "$d/governor" 2>/dev/null
    done
}

# MTK: Mali power policy + fpsgo/GED (AZenith), gated by config.
set_render_mtk() {
    local d
    for d in /sys/devices/platform/*.mali; do
        [ -e "$d/power_policy" ] && \
            echo "always_on" > "$d/power_policy" 2>/dev/null
    done
    set_governor "$AURIA_CPU_GOVERNOR"
    if [ "$AURIA_MTK_FPSGO" = "1" ]; then
        a_write "1" /sys/module/ged/parameters/gx_game_mode
        a_write "1" /sys/module/ged/parameters/gx_force_cpu_boost
        a_write "0" /sys/kernel/fpsgo/fbt/boost_ta
        a_write "1" /sys/kernel/fpsgo/fstb/boost_ta
        a_write "100" /sys/kernel/ged/hal/gpu_boost_level
        L "MTK fpsgo: on"
    fi
}

# MTK walt tuning (AZenith) - advanced, off by default.
set_walt() {
    [ "$AURIA_WALT" = "1" ] || return 0
    local policy dir freqs top n i loads cur=95
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        dir="$policy/walt"
        [ -d "$dir" ] || continue
        freqs=$(cat "$policy/scaling_available_frequencies" 2>/dev/null)
        [ -n "$freqs" ] || continue
        top=$(echo "$freqs" | tr ' ' '\n' | sort -rn | head -n 6)
        n=$(echo "$top" | wc -l)
        loads=""
        i=0
        while [ "$i" -lt "$n" ]; do
            loads="$loads $cur"; cur=$((cur - 5)); [ "$cur" -lt 10 ] && cur=10
            i=$((i + 1))
        done
        a_write "$(echo "$top" | tr '\n' ' ')" "$dir/efficient_freq"
        a_write "${loads# }" "$dir/target_loads"
        a_write "8000" "$dir/up_rate_limit_us"
        a_write "12000" "$dir/down_rate_limit_us"
    done
    L "walt: applied"
}

set_render() {
    [ "$AURIA_RENDER" = "1" ] || return 0
    case "$AURIA_SOC" in
        mediatek) set_render_mtk ;;
        qualcomm) set_render_qc "$AURIA_CPU_GOVERNOR" ;;
    esac
    set_walt
    setprop debug.composition.type gpu 2>/dev/null
    L "render: applied"
}

# ===================================================================
# (5) IO / VM
# ===================================================================

set_io() {
    [ "$AURIA_IO" = "1" ] || return 0
    local b
    for b in /sys/block/mmcblk* /sys/block/sd*; do
        [ -f "$b/queue/scheduler" ] || continue
        a_write_any "mq-deadline" "$b/queue/scheduler" "$b/queue/scheduler"
        a_write "2048" "$b/queue/read_ahead_kb"
    done
    L "io: applied"
}

set_vm() {
    [ "$AURIA_VM" = "1" ] || return 0
    a_sysctl vm/swappiness 100
    a_sysctl vm/vfs_cache_pressure 100
    a_sysctl vm/dirty_ratio 90
    a_sysctl vm/dirty_background_ratio 5
    a_sysctl kernel/sched_autogroup_enabled 1
    L "vm: applied"
}

set_misc() {
    [ "$AURIA_KILL_LOGD" = "1" ] || return 0
    for logger in logd traced statsd tcpdump cnss_diag subsystem_ramdump charge_logger wlan_logging; do
        stop "$logger" 2>/dev/null
    done
    L "loggers: stopped"
}

# ===================================================================
# RUN
# ===================================================================

apply_tweaks() {
    local mode="${1:-$AURIA_PROFILE}"
    detect_soc
    L "v$AURIA_VER start (soc=$AURIA_SOC profile=$mode)"
    set_thermal
    case "$mode:$AURIA_SOC" in
        *:mediatek) mtk_ppm_policy "$mode"; mtk_dvfsrc "$mode" ;;
    esac
    set_charging
    set_display
    set_render
    set_io
    set_vm
    set_misc
    L "done"
}