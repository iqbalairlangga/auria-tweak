#!/bin/sh
# Auria Tweak - Build script
# Creates the flashable Magisk/KernelSU module zip

# Get version from module.prop
MOD_VERSION=$(grep "^version=" module.prop | cut -d= -f2)
AURIA_MODULE_ID="auria_tweak"

echo "Building Auria Tweak v${MOD_VERSION}..."

# Create temp build directory
BUILD_DIR="build_tmp"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/common"

# Copy core module files
cp module.prop "$BUILD_DIR/"
cp customize.sh "$BUILD_DIR/"
cp service.sh "$BUILD_DIR/"
cp post-fs-data.sh "$BUILD_DIR/"

# Copy common scripts
cp common/util_functions.sh "$BUILD_DIR/common/"
cp common/auria_tweak.sh "$BUILD_DIR/common/"

# Copy system overlay if it exists
if [ -d "system" ]; then
    cp -r system "$BUILD_DIR/"
fi

# Create README inside module (optional)
echo "Auria Tweak v${MOD_VERSION}" > "$BUILD_DIR/README"

# Create the zip
AURIA_ZIP="${AURIA_MODULE_ID}-v${MOD_VERSION}.zip"
cd "$BUILD_DIR"
zip -r "../$AURIA_ZIP" . -x ".*" >/dev/null
cd ..

# Cleanup
rm -rf "$BUILD_DIR"

echo "Done! Created: $AURIA_ZIP"
ls -lh "$AURIA_ZIP"
