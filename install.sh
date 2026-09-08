#!/system/bin/sh
# Auria Tweak - standalone installer (terminal/ADB/manual)
# Installs this module tree into /data/adb/modules/auria_tweak
# usable by Magisk, KernelSU, and MMRL alike.
#
# Usage:
#   (as root) sh /path/to/auria_tweak/install.sh
#   adb shell "su -c 'sh /sdcard/Download/auria_tweak/install.sh'"
#
# Existing config.sh is PRESERVED on update; fresh modules get defaults.

SRC=${0%/*}
DST=/data/adb/modules/auria_tweak
AURIA_VER="5.6"

ui_print() { echo "$1"; }

# --- sanity ---
[ "$(id -u 2>/dev/null)" = "0" ] || { ui_print "Error: jalankan sebagai root."; exit 1; }
[ -d "$SRC" ] || { ui_print "Error: tidak dapat menemukan direktori modul."; exit 1; }
[ -d "$DST" ] || mkdir -p "$DST" 2>/dev/null || { ui_print "Error: /data/adb/modules tidak writable."; exit 1; }

# --- guard: jangan self-copy dari dalam destination ---
[ "$SRC" = "$DST" ] && {
    ui_print "Auria Tweak v$AURIA_VER sudah terpasang."
    ui_print "Jalankan 'sh $0' dari direktori lain untuk update."
    exit 0
}

ui_print "=============================="
ui_print "   Auria Tweak v$AURIA_VER"
ui_print "   MediaTek Helio / Snapdragon"
ui_print "=============================="

# --- backup user config before refresh ---
if [ -f "$DST/common/config.sh" ]; then
    cp -f "$DST/common/config.sh" "$DST/common/config.sh.bak" 2>/dev/null
    ui_print "  - Config lama disimpan: config.sh.bak"
fi

# --- install module tree ---
cp -af "$SRC/." "$DST/" 2>/dev/null || { ui_print "Error: gagal menyalin modul."; exit 1; }
chmod -R 0644 "$DST/." 2>/dev/null
chmod 0755 "$DST" "$DST/common" "$DST/webroot" 2>/dev/null
for f in "$DST"/*.sh "$DST"/*.prop "$DST"/common/*.sh; do
    [ -e "$f" ] && chmod 0755 "$f" 2>/dev/null
done

# --- anti-bootloop baseline ---
echo "BOOTCOUNT=0" > "$DST/count.sh"
chmod 0644 "$DST/count.sh"

# --- detect SoC family (inline, self-contained) ---
soc_detect() {
    local hw
    hw=$(getprop ro.board.platform 2>/dev/null)
    case "$hw" in
        mt*)                          echo "MediaTek" ;;
        sm[0-9]*|sdm[0-9]*|msm[0-9]*|kona|lito|bengal|lahaina|taro|kalama|pineapple|parrot)
                                      echo "Snapdragon" ;;
        *)                            echo "${hw:-unknown}" ;;
    esac
}

ui_print "  - SoC        : $(soc_detect)"
ui_print "  - Platform   : $(getprop ro.board.platform 2>/dev/null)"
ui_print "  - Profile    : $(grep '^AURIA_PROFILE' "$DST/common/config.sh" 2>/dev/null | cut -d= -f2)"
ui_print ""
ui_print "  Installed ke : $DST"
ui_print "  Config      : $DST/common/config.sh"
ui_print "  Reboot untuk menerapkan."

exit 0