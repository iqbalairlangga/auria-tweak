#!/bin/sh
# Auria Tweak - build script
# Produces a flashable module zip (module.prop drives the version).
set -e

AURIA_MODULE_ID="auria_tweak"
MAX_SIZE_MB=10

mod_version=$(grep "^version=" module.prop | cut -d= -f2 | tr -d '[:space:]')
out_zip="${AURIA_MODULE_ID}-${mod_version}.zip"

echo "Building Auria Tweak ${mod_version} ..."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp module.prop system.prop customize.sh service.sh post-fs-data.sh install.sh uninstall.sh "$tmp/"
mkdir -p "$tmp/common" "$tmp/webroot"
cp common/config.sh common/engine.sh common/helpers.sh common/cli.sh "$tmp/common/"
cp webroot/index.html "$tmp/webroot/"

(cd "$tmp" && zip -qr "../$out_zip" . -x '.*')

size_kb=$(du -k "$out_zip" | cut -f1)
echo "Created $out_zip (${size_kb} KB)"

if [ "$size_kb" -gt $((MAX_SIZE_MB * 1024)) ]; then
    echo "Error: $out_zip exceeds ${MAX_SIZE_MB}MB budget" >&2
    rm -f "$out_zip"
    exit 1
fi

ls -lh "$out_zip"