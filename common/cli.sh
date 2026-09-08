#!/system/bin/sh
# Auria Tweak - CLI entrypoint (dipakai WebUI: "Terapkan" / adb shell)
# Usage: sh cli.sh [profile]
# Loads config and applies tweaks immediately.

MODDIR=${0%/*}
. "$MODDIR/helpers.sh"
. "$MODDIR/config.sh"
. "$MODDIR/engine.sh"

apply_tweaks "${1:-$AURIA_PROFILE}"

exit 0