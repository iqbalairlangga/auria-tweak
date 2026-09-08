#!/system/bin/sh
# Auria Tweak - early boot (post-fs-data mode)
# Single-instance guard (KernelSU metamodule boots twice) +
# anti-bootloop counter + earliest VM nodes.

MODDIR=${0%/*}
LOCK="/dev/.auria_tweak_single"

# KernelSU metamodule can run post-fs-data twice; run once.
[ -f "$LOCK" ] && exit 0
touch "$LOCK"

# ---- anti-bootloop ----
COUNT=0
[ -f "$MODDIR/count.sh" ] && . "$MODDIR/count.sh"
COUNT=$((COUNT + 1))
if [ "$COUNT" -gt 1 ]; then
    touch "$MODDIR/disable"
    rm -f "$MODDIR/count.sh"
    sed -i 's/^description=.*/description=anti-bootloop: module auto-disabled (reboot safe)/' \
        "$MODDIR/module.prop" 2>/dev/null
    exit 1
fi
echo "BOOTCOUNT=1" > "$MODDIR/count.sh"

# Runtime files at module root; fallback to common/ if a manager kept that layout.
if [ -f "$MODDIR/helpers.sh" ]; then
    . "$MODDIR/helpers.sh"
    . "$MODDIR/config.sh"
else
    . "$MODDIR/common/helpers.sh"
    . "$MODDIR/common/config.sh"
fi

# Earliest VM balance while fs is fresh.
[ "$AURIA_VM" = "1" ] && {
    a_sysctl vm/overcommit_ratio 60
}

exit 0