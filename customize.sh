#!/system/bin/sh
# Auria Tweak - installer
# Contexts:
#   1. Magisk: sourced by META-INF/com/google/android/update-binary (MODPATH set)
#   2. KernelSU / ResukiSU / APatch native: executed from module dir (no MODPATH)
#   3. Standalone manual: sh /path/to/customize.sh

# ui_print is provided by Magisk's util_functions.sh; fallback for everyone else.
command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

# --- locate module dir -----------------------------------------------------
# Magisk sets MODPATH. KernelSU/ResukiSU run customize.sh from the module dir.
if [ -z "$MODPATH" ]; then
    if [ -f "$PWD/module.prop" ]; then
        MODPATH=$PWD
    else
        MODPATH=${0%/*}
    fi
fi

# --- locate runtime dir ----------------------------------------------------
# Runtime scripts live at module root (helpers.sh/config.sh/engine.sh/cli.sh).
# Some managers flatten common/ to root; probe both just in case.
RUNTIME_DIR=""
for c in "$MODPATH" "${TMPDIR}" "${0%/*}" "$PWD" "$MODPATH/common"; do
    if [ -f "$c/helpers.sh" ]; then
        RUNTIME_DIR="$c"
        break
    fi
done
if [ -z "$RUNTIME_DIR" ]; then
    ui_print "Error: helpers.sh tidak ditemukan."
    exit 1
fi
. "$RUNTIME_DIR/helpers.sh"

# --- root manager lock (Magisk / KernelSU / APatch only) -------------------
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
ui_print "  Profile    : $(grep '^AURIA_PROFILE' "$RUNTIME_DIR/config.sh" | cut -d= -f2)"
ui_print ""
ui_print "  Features:"
ui_print "   - Thermal soften (mode 1)"
ui_print "   - Battery & charging"
ui_print "   - Display / SF tuning (Zeta)"
ui_print "   - Render (GPU/CPU governor)"
ui_print "   - IO (mq-deadline) + VM"
ui_print "   - Anti-bootloop self-heal"
ui_print ""
ui_print "  Config: /data/adb/modules/auria_tweak/config.sh"
ui_print "  Reboot after install to apply."
ui_print "  Uninstall: kelola via manager (restore otomatis ke stock)."