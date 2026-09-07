#!/system/bin/sh
# Auria Tweak - service.sh
# Executed in late_start service mode

MODDIR=${0%/*}
SOCRACE=$(cat "$MODDIR/soc_type.conf" 2>/dev/null)

# Copy tweak script to service.d for execution
if [ -f "$MODDIR/common/auria_tweak.sh" ]; then
    # Run the tweak script directly
    sh "$MODDIR/common/auria_tweak.sh" &
elif [ -f "$MODDIR/common/util_functions.sh" ]; then
    . "$MODDIR/common/util_functions.sh"
    log "auria_tweak.sh not found, running inline"
fi

exit 0
