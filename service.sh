#!/system/bin/sh
# Auria Tweak - boot service (late_start service mode)
# Anti-bootloop reset + initial sanity, then run engine detached.

MODDIR=${0%/*}
. "$MODDIR/common/helpers.sh"
. "$MODDIR/common/config.sh"
. "$MODDIR/common/engine.sh"

# Wait for framework so props/settings/thermal are available.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 3
done

# Boot completed = reboot was safe. Reset anti-bootloop counter.
echo "BOOTCOUNT=0" > "$MODDIR/count.sh" 2>/dev/null

# Clear stale single-instance lock.
rm -f /dev/.auria_tweak_single 2>/dev/null

# Run engine; keeps system responsive even if an IO node is stuffed.
apply_tweaks &
exit 0