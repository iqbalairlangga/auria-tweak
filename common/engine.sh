#!/system/bin/sh
# Auria Tweak - main engine (clean & stable)
# Loaded by service.sh with helpers + config sourced.

L() { a_log "$1"; }

# ===================================================================
# (1) THERMAL - soften only (mode 1), no kill mode
# ===================================================================
set_thermal() {
    [ "$AURIA_THERMAL" = "1" ] || return 0
    local z
    case "$AURIA_SOC" in
        mediatek)
            a_write "0" /sys/module/thermal/parameters/enabled
            a_write "0" /proc/cpufreq/cpufreq_imax_enable
            for z in /sys/class/thermal/thermal_zone*/mode; do a_write disabled "$z"; done
            L "MTK thermal: soften"
            ;;
        qualcomm)
            a_write_any "0" /sys/module/msm_thermal/parameters/enabled \
                /sys/module/msm_thermal/parameters/therm_limit_disable
            for z in /sys/class/thermal/thermal_zone*/mode; do a_write disabled "$z"; done
            L "QC thermal: soften"
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
zeta_sf_props() {
    resetprop debug.sf.disable_backpressure 1 2>/dev/null
    resetprop debug.sf.disable_hwc 1 2>/dev/null
    resetprop debug.sf.latch_unsignaled 1 2>/dev/null
    resetprop ro.surface_flinger.max_frame_buffer_acquired_buffers 3 2>/dev/null
    resetprop debug.gralloc.enable_fb_ubwc 0 2>/dev/null
    resetprop ro.max.fling_velocity 10000 2>/dev/null
}

set_display() {
    [ "$AURIA_DISPLAY" = "1" ] || return 0
    zeta_sf_props
    case "$AURIA_REFRESH" in
        60|90|120)
            setprop persist.vendor.peak_refresh_rate "$AURIA_REFRESH" 2>/dev/null
            setprop video.peak.refresh.rate "$AURIA_REFRESH" 2>/dev/null
            ;;
    esac
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

set_cpu_mode() {
    local mode="$1" gov_override
    case "$mode" in
        performance) gov_override="performance" ;;
        powersave)   gov_override="powersave" ;;
        balanced)    gov_override="schedutil" ;;
        *)           return 0 ;;
    esac
    AURIA_CPU_GOVERNOR="$gov_override"
    set_governor "$gov_override"
    L "cpu mode: ${mode} (gov=${gov_override})"
}

set_render_mtk() {
    local d
    for d in /sys/devices/platform/*.mali; do
        [ -e "$d/power_policy" ] && echo "always_on" > "$d/power_policy" 2>/dev/null
    done
    set_governor "$AURIA_CPU_GOVERNOR"
}

set_render() {
    [ "$AURIA_RENDER" = "1" ] || return 0
    case "$AURIA_SOC" in
        mediatek) set_render_mtk ;;
        qualcomm) set_render_qc "$AURIA_CPU_GOVERNOR" ;;
    esac
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

# ===================================================================
# RUN
# ===================================================================
apply_tweaks() {
    local mode="${1:-$AURIA_PROFILE}"
    detect_soc
    L "v$AURIA_VER start (soc=$AURIA_SOC profile=$mode)"
    set_cpu_mode "$mode"
    set_thermal
    case "$mode:$AURIA_SOC" in
        *:mediatek) mtk_ppm_policy "$mode"; mtk_dvfsrc "$mode" ;;
    esac
    set_charging
    set_display
    set_render
    set_io
    set_vm
    L "done"
}

# ===================================================================
# MTK: PPM & dvfsrc (kept from AZenith - proven stable)
# ===================================================================
mtk_ppm_policy() {
    [ "$AURIA_MTK_PPM" = "1" ] || return 0
    [ -f /proc/ppm/policy_status ] || return 0
    local mode="$1" idx
    local clamp=1
    [ "$mode" = "performance" ] && clamp=0
    awk -F'[][]' '/FORCE_LIMIT|PWR_THRO|THERMAL|USER_LIMIT/{print $2}' /proc/ppm/policy_status 2>/dev/null | while read -r idx; do
        [ -n "$idx" ] && echo "$idx $clamp" > /proc/ppm/policy_status 2>/dev/null
    done
}

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