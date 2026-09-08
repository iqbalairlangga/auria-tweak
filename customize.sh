#!/system/bin/sh
# Auria Tweak - installer (sourced by META-INF update-binary)
# SoC detection + anti-bootloop baseline.

# ui_print is provided by Magisk's util_functions.sh
# MODPATH is set by update-binary
# Helpers are extracted to same dir as customize.sh

. "$(dirname "$0")/helpers.sh"

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
echo "BOOTCOUNT=0" > "$MODPATH/count.sh"

ui_print "  SoC family : $AURIA_SOC"
ui_print "  Platform   : $(getprop ro.board.platform 2>/dev/null)"
ui_print "  Profile    : $(grep '^AURIA_PROFILE' "$MODPATH/common/config.sh" | cut -d= -f2)"
ui_print ""
ui_print "  Features:"
ui_print "   - Thermal soften (mode 1)"
ui_print "   - Battery & charging"
ui_print "   - Display / SF tuning (Zeta)"
ui_print "   - Render (GPU/CPU governor)"
ui_print "   - IO (mq-deadline) + VM"
ui_print "   - Anti-bootloop self-heal"
ui_print ""
ui_print "  Config: /data/adb/modules/auria_tweak/common/config.sh"
ui_print "  Reboot after install to apply."
ui_print "  Uninstall: kelola via manager (restore otomatis ke stock)."

exit 0