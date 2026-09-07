#!/system/bin/sh
# Auria Tweak - Main service script
# Applied on boot for all supported devices

# Determine module root (auria_tweak.sh lives in $MODDIR/common/)
SCRIPT_DIR=${0%/*}
MODDIR=${MODDIR:-$(dirname "$SCRIPT_DIR")}
SOCRACE=$(cat "$MODDIR/soc_type.conf" 2>/dev/null)

# shellcheck disable=SC1090
. "$MODDIR/common/util_functions.sh"

log "=== Auria Tweak starting (SOC: $SOCRACE) ==="

# Wait for system to be ready
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 5
done
sleep 10

log "System booted, applying tweaks..."

# --- Apply universal tweaks regardless of SoC ---
apply_universal_tweaks() {
    # Build.prop / render optimizations via settings
    settings put global window_animation_scale 0.5 2>/dev/null
    settings put global transition_animation_scale 0.5 2>/dev/null
    settings put global animator_duration_scale 0.5 2>/dev/null

    # Increase rendering performance via GPU
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_rail_on
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_clk_on
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_bus_on
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_no_nap

    # Disable some debug/logging for performance
    write_any "0" /sys/kernel/debug/kgsl/kgsl-3d0/force_bus_on
    setprop debug.sf.nobootanimation 1 2>/dev/null
    setprop debug.hwui.renderer opengl 2>/dev/null

    # View/scroll cache to increase UI performance
    setprop persist.sys.ui.hw 1 2>/dev/null
    setprop persist.sys.composition.type gpu 2>/dev/null
    setprop debug.composition.type gpu 2>/dev/null

    log "Universal tweaks applied"
}

# --- Charging optimization (works on both) ---
apply_charging_tweaks() {
    # Fast charge over USB
    write_any "1" /sys/class/power_supply/usb/device/fast_charge_current
    write_any "2000000" /sys/class/power_supply/usb/device/max_charge_current
    write_any "2000000" /sys/class/power_supply/usb/device/charge_current_override
    write_any "2" /sys/class/power_supply/usb/device/fast_charge

    # Charging control
    write_any "0" /sys/class/power_supply/battery/cable_type
    write_any "1" /sys/class/power_supply/battery/charging_enabled
    write_any "2000000" /sys/class/power_supply/battery/constant_charge_current_max
    write_any "4400000" /sys/class/power_supply/battery/constant_charge_voltage_max

    # USB fast charge
    write_any "0" /sys/class/power_supply/main/usb_hc
    write_any "1" /sys/module/qpnp_charger/parameters/fastchg
    write_any "1" /sys/module/battery/parameters/fastchg

    log "Charging tweaks applied"
}

# --- Display optimization (works on both) ---
apply_display_tweaks() {
    # Set RGB/color to vibrant
    write_any "255 255 255" /sys/class/graphics/fb0/rgb
    write_any "255" /sys/class/graphics/fb0/vibrant

    # Brightness optimization
    write_any "1" /sys/class/leds/lcd-backlight/max_brightness/auto_brightness 2>/dev/null
    write_any "1" /sys/class/backlight/mtkfb/max_brightness 2>/dev/null

    # Refresh rate boost
    setprop debug.vendor.enable_adaptive_refresh 1 2>/dev/null
    setprop persist.vendor.peak_refresh_rate 120 2>/dev/null

    log "Display tweaks applied"
}

# --- Apply SoC-specific tweaks ---
if [ "$SOCRACE" = "mediatek" ]; then
    log "Applying MediaTek Helio tweaks..."
    # MediaTek-specific thermal + perf

    # Disable thermal throttling (MTK uses .thm files / thermal services)
    stop thermal 2>/dev/null
    stop thermal_manager 2>/dev/null
    stop thermalHAL 2>/dev/null
    write_any "0" /sys/module/thermal/parameters/thermal_zone
    write_any "0" /sys/kernel/thermal/parameters/enable
    write_any "0" /sys/class/thermal/thermal_message/temperature_wakeup

    # MTK GPU boost
    write_any "0" /proc/gpufreq/gpufreq_opp_dump 2>/dev/null
    write_any "1000000000" /proc/gpufreq/gpufreq_opp_freq 2>/dev/null
    write_any "3" /proc/gpufreq/gpufreq_opp_volt 2>/dev/null
    write_any "1" /proc/mali/cap_clock 2>/dev/null
    write_any "1" /proc/mali/limit 2>/dev/null
    write_any "-1" /sys/module/mali/parameters/mali_max_fallback_core_mask 2>/dev/null

    # MTK EEM (energy efficiency management) - boost
    write_any "1" /proc/eem/eem_enable
    write_any "0" /proc/eem/eem_irq_affinity 2>/dev/null
    write_any "1" /proc/eem/enable 2>/dev/null

    # MTK CPU performance
    write_any "2" /proc/cpufreq/cpufreq_cur_freq
    write_any "1" /proc/cpufreq/cpufreq_thermal_limit_enable 2>/dev/null
    write_any "0" /proc/cpufreq/cpufreq_hotplug_limit_enable 2>/dev/null
    write_any "0" /sys/module/cpufreq/parameters/cpufreq_limiter 2>/dev/null

    # Disable MTK thermal engine explicitly (Helio G series)
    write_any "0" /sys/kernel/thermal/thermal_zone*/policy 2>/dev/null
    write_any "0" /sys/class/thermal/thermal_zone*/mode 2>/dev/null

    # MTK boost for Helio gaming
    write_any "1" /proc/gpufreq/gpufreq_power_dump 2>/dev/null
    write_any "1" /proc/gpufreq/gpufreq_limit 2>/dev/null
    write_any "0" /sys/module/ged/parameters/ged_boost_enable 2>/dev/null

    setprop ro.sys.fw.bg_apps_limit 8 2>/dev/null

elif [ "$SOCRACE" = "qualcomm" ]; then
    log "Applying Qualcomm Snapdragon tweaks..."
    # Qualcomm-specific thermal + perf

    # Disable thermal throttling
    stop thermal-engine 2>/dev/null
    stop thermal_engine 2>/dev/null
    stop thermal 2>/dev/null
    stop thermalHal 2>/dev/null
    write_any "0" /sys/module/msm_thermal/parameters/enabled
    write_any "0" /sys/module/msm_thermal/parameters/vdd_restriction_enabled
    write_any "0" /sys/module/msm_thermal/parameters/thermal_limit_disable
    write_any "0" /sys/module/msm_thermal/parameters/core_control_enabled
    write_any "0" /sys/module/msm_thermal/parameters/frequency_mitigation_enabled
    write_any "0" /sys/module/msm_thermal/parameters/shutdown_temp 2>/dev/null

    # QC thermal driver (newer)
    write_any "disabled" /sys/class/thermal/thermal_message/config 2>/dev/null
    write_any "0" /sys/kernel/thermal/thermal_zone*/policy 2>/dev/null
    write_any "0" /sys/class/thermal/thermal_zone*/mode 2>/dev/null

    # Adreno GPU boost
    write_any "1" /sys/class/kgsl/kgsl-3d0/bus_split
    write_any "0" /sys/class/kgsl/kgsl-3d0/force_rail_on
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_clk_on
    write_any "1" /sys/class/kgsl/kgsl-3d0/force_bus_on
    write_any "1000000000" /sys/class/kgsl/kgsl-3d0/max_gpuclk
    write_any "1" /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 2>/dev/null

    # Set GPU governor to performance
    write_any "performance" /sys/class/kgsl/kgsl-3d0/devfreq/governor

    # CPU boost via QoS
    write_any "0" /sys/devices/system/cpu/cpu*/cpufreq/interactive/above_hispeed_delay 2>/dev/null
    write_any "performance" /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null

    # Kryo/Snapdragon perf task placement
    setprop ro.sys.fw.bg_apps_limit 8 2>/dev/null
    setprop persist.sys.boost.performance_mode 1 2>/dev/null

    # Disable SD card fsync for speed (with caution)
    write_any "0" /sys/block/mmcblk*/queue/fsync 2>/dev/null

else
    log "Applying generic tweaks..."
    # Generic fallback
    stop thermal 2>/dev/null
fi

# --- Apply more universal performance tweaks ---
apply_universal_tweaks
apply_charging_tweaks
apply_display_tweaks

# --- IO Scheduler optimization ---
for storage in /sys/block/sd* /sys/block/mmcblk*; do
    [ -e "$storage/queue/scheduler" ] && write_sysfs "$storage/queue/scheduler" "fiops"
    [ -e "$storage/queue/read_ahead_kb" ] && write_sysfs "$storage/queue/read_ahead_kb" "2048"
    [ -e "$storage/queue/iostats" ] && write_sysfs "$storage/queue/iostats" "0"
done

# --- Disable unnecessary logging ---
write_any "0" /sys/kernel/logger_mode
setprop log.tag.* V 2>/dev/null

log "=== Auria Tweak applied successfully ==="
