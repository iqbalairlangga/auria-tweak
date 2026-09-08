#!/system/bin/sh
# Auria Tweak - CLI entrypoint (WebUI / adb shell)
# Usage: sh cli.sh [profile]
# Loads config and applies tweaks immediately (no reboot).

MODDIR=${0%/*}

if [ -n "$1" ]; then
    case "$1" in
        balanced|performance|powersave)
            sed -i "s/^AURIA_PROFILE=.*/AURIA_PROFILE=$1/" "$MODDIR/config.sh" 2>/dev/null
            ;;
    esac
fi

. "$MODDIR/helpers.sh"
. "$MODDIR/config.sh"
. "$MODDIR/engine.sh"

apply_tweaks "${1:-$AURIA_PROFILE}"

exit 0