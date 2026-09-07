#!/system/bin/sh
# Auria Tweak - early boot (post-fs-data)
# Minimal early VM balance; heavy lifting happens in service.sh.

MODDIR=${0%/*}
. "$MODDIR/common/helpers.sh"
. "$MODDIR/common/config.sh"

# Quick, safe early knobs while the filesystem is known-good.
[ "$AURIA_VM" = "1" ] && {
    a_sysctl vm/overcommit_ratio 60
    a_sysctl vm/stat_interval 1
}

exit 0