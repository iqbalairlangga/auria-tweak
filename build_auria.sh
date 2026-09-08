#!/bin/sh
# Auria Tweak - build script
# Produces a flashable module zip with proper Magisk/KSU/APatch structure.
set -e

AURIA_MODULE_ID="auria_tweak"
MAX_SIZE_MB=10

mod_version=$(grep "^version=" module.prop | cut -d= -f2 | tr -d '[:space:]')
out_zip="${AURIA_MODULE_ID}-${mod_version}.zip"

echo "Building Auria Tweak ${mod_version} ..."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Create directory structure
mkdir -p "$tmp/META-INF/com/google/android"
mkdir -p "$tmp/webroot/css"
mkdir -p "$tmp/webroot/js"
mkdir -p "$tmp/webroot/assets"
mkdir -p "$tmp/system"
mkdir -p "$tmp/common"

# Copy root files
cp module.prop customize.sh service.sh post-fs-data.sh uninstall.sh install.sh "$tmp/"
cp system.prop "$tmp/system/"

# Copy META-INF
cp META-INF/com/google/android/update-binary "$tmp/META-INF/com/google/android/"
cp META-INF/com/google/android/updater-script "$tmp/META-INF/com/google/android/"

# Copy common
cp common/config.sh common/engine.sh common/helpers.sh common/cli.sh "$tmp/common/"

# Copy webroot
cp webroot/index.html "$tmp/webroot/"
cp webroot/css/style.css "$tmp/webroot/css/"
cp webroot/js/main.js "$tmp/webroot/js/"

# Pack
(cd "$tmp" && zip -qr "../$out_zip" . -x '.*')

# Enforce size budget
size_kb=$(du -k "$out_zip" | cut -f1)
echo "Created $out_zip (${size_kb} KB)"

if [ "$size_kb" -gt $((MAX_SIZE_MB * 1024)) ]; then
    echo "Error: $out_zip exceeds ${MAX_SIZE_MB}MB budget" >&2
    rm -f "$out_zip"
    exit 1
fi

ls -lh "$out_zip"