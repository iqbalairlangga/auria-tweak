#!/system/bin/sh
# Auria Tweak - boot service (late_start)
# Prepare environment then delegate to the engine.

MODDIR=${0%/*}

# User may tune config on-device; source from module dir.
. "$MODDIR/common/helpers.sh"
. "$MODDIR/common/config.sh"
. "$MODDIR/common/engine.sh"

# Wait for the framework so props/settings/thermal are touchable.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 5
done

apply_tweaks &

exit 0