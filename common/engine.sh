#!/system/bin/sh
# Auria Tweak - main engine
# Loaded by service.sh with MODDIR set and helpers sourced.

L() { a_log "$1"; }

# ============ THERMAL ============

set_thermal() {
    [ "$AURIA_THERMAL" = "0" ] && return 0
    case "$AURIA_SOC" in
        mediatek)
            case "$AURIA_THERMAL" in
                1)
                    a_write "0" /sys/module/thermal/parameters/enabled
                    a_write_any "0" /proc/cpufreq/cpufreq_imax_enable \
                        /sys/module/cpufreq/parameters/cpufreq_imax_enable
                    L "MTK thermal: softened"
                    ;;
                2)
                    a_write "0" /sys/module/thermal/parameters/enabled
                    for z in /sys/class/thermal/thermal_zone*/mode; do
                        [ -w "$z" ] && echo disabled > "$z" 2>/dev/null
                    done
                    L "MTK thermal: disabled"
                    ;;
            esac
            ;;
        qualcomm)
            case "$AURIA_THERMAL" in
                1)
                    a_write_any "0" /sys/module/msm_thermal/parameters/enabled \
                        /sys/module/msm_thermal/parameters/therm_limit_disable
                    L "QC thermal: softened"
                    ;;
                2)
                    a_write_any "0" /sys/module/msm_thermal/parameters/enabled \
                        /sys/module/msm_thermal/parameters/vdd_restriction_enabled
                    for z in /sys/class/thermal/thermal_zone*/mode; do
                        [ -w "$z" ] && echo disabled > "$z" 2>/dev/null
                    done
                    L "QC thermal: disabled"
                    ;;
            esac
            ;;
    esac
}

# ============ CHARGING ============

set_charging() {
    [ "$AURIA_CHARGING" = "1" ] || return 0
    a_write "1" /sys/class/power_supply/battery/charging_enabled
    if [ "$AURIA_CHARGE_CURRENT" -gt 0 ]; then
        a_write_any "$AURIA_CHARGE_CURRENT" \
            /sys/class/power_supply/battery/constant_charge_current_max \
            /sys/class/power_supply/main/current_max \
            /sys/class/power_supply/usb/current_max
    fi
    L "charging: current=${AURIA_CHARGE_CURRENT}uA"
}

# ============ DISPLAY ============

set_display() {
    [ "$AURIA_DISPLAY" = "1" ] || return 0
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

# ============ RENDERING ============

set_render() {
    [ "$AURIA_RENDER" = "1" ] || return 0
    # GPU governor (Adreno kgsl / Mali devfreq)
    a_write_any "performance" /sys/class/kgsl/kgsl-3d0/devfreq/governor \
        /sys/class/gpu/devfreq/devfreq0/governor
    # GPU freq bump + no naps
    a_write_any "166500000" /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
    a_write_any "1" /sys/class/kgsl/kgsl-3d0/force_no_nap /sys/module/mali/parameters/mali_tgid
    # Renderer tuning
    setprop debug.hwui.renderer skiavk 2>/dev/null
    setprop debug.composition.type gpu 2>/dev/null
    # CPU governor per config
    set_best_governor "$AURIA_CPU_GOVERNOR"
    L "render: applied"
}

# ============ IO / VM ============

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

# ============ RUN ============

apply_tweaks() {
    detect_soc
    L "v$AURIA_VER start (soc=$AURIA_SOC)"
    set_thermal
    set_charging
    set_display
    set_render
    set_io
    set_vm
    L "done"
}