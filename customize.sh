#!/system/bin/sh
# Auria Tweak - installer
# SoC detection + friendly status. No files copied here: Magisk/MKSU
# place the module tree automatically; tweaks run from service.sh.

MODDIR=${0%/*}
. "$MODDIR/common/helpers.sh"

[ "$(id -u 2>/dev/null)" = "0" ] || { echo "Error: run via root manager"; exit 1; }

ui_print "=============================="
ui_print "   Auria Tweak v$AURIA_VER"
ui_print "   MediaTek Helio / Snapdragon"
ui_print "=============================="

detect_soc

ui_print "  SoC family : $AURIA_SOC"
ui_print "  Platform   : $(getprop ro.board.platform 2>/dev/null)"
ui_print ""
ui_print "  Features:"
ui_print "   - Thermal policy"
ui_print "   - Battery & charging"
ui_print "   - Display tuning"
ui_print "   - Render (GPU/CPU) tuning"
ui_print "   - IO & VM balancing"
ui_print ""
ui_print "  Install complete. Reboot to apply."

exit 0