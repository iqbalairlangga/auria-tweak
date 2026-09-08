#!/system/bin/sh
# Auria Tweak - installer
# SoC detection (robust, Raco-style getprop battery + sysfs fallback)
# plus an initial count.sh so anti-bootloop has a baseline.

MODDIR=${0%/*}
. "$MODDIR/common/helpers.sh"

ui_print "=============================="
ui_print "   Auria Tweak v$AURIA_VER"
ui_print "   MediaTek Helio / Snapdragon"
ui_print "=============================="

detect_root_mgr
case "$AURIA_ROOT" in
    magisk|ksu|apatch)
        ui_print "  Root manager: $AURIA_ROOT (supported)"
        ;;
    *)
        ui_print "!"
        ui_print "! Root manager tidak dikenali."
        ui_print "! Auria Tweak hanya mendukung Magisk / KernelSU / APatch."
        ui_print "!"
        exit 1
        ;;
esac

detect_soc

# Ensure anti-bootloop baseline (0 so first boot never trips).
echo "BOOTCOUNT=0" > "$MODDIR/count.sh"

ui_print "  SoC family : $AURIA_SOC"
ui_print "  Platform   : $(getprop ro.board.platform 2>/dev/null)"
ui_print "  Profile    : $(grep '^AURIA_PROFILE' "$MODDIR/common/config.sh" | cut -d= -f2)"
ui_print ""
ui_print "  Features:"
ui_print "   - Thermal policy (0/1/2)"
ui_print "   - Battery & charging"
ui_print "   - Display / SF tuning"
ui_print "   - Render (GPU/CPU) tuning"
ui_print "   - IO, VM, misc hygiene"
ui_print "   - Anti-bootloop self-heal"
ui_print ""
ui_print "  Config: /data/adb/modules/auria_tweak/common/config.sh"
ui_print "  Reboot after install to apply."
ui_print "  Uninstall: kelola via manager (restore otomatis ke stock)."
exit 0