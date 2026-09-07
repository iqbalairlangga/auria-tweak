#!/system/bin/sh
# Auria Tweak - installation script
# Detect SoC platform and apply appropriate tweaks

# Source helper if available
[ -f "$MODDIR/common/util_functions.sh" ] && . "$MODDIR/common/util_functions.sh"

ui_print " "
ui_print "======================================"
ui_print "   AURIA TWEAK INSTALLER"
ui_print "   Performance & Battery Optimizer"
ui_print "======================================"
ui_print " "

# --- SoC Detection ---
SOC=$(getprop ro.board.platform)
SOC2=$(getprop ro.soc.model 2>/dev/null)
SOC_MANUF=$(getprop ro.boot.hardware 2>/dev/null)
CPU_ABI=$(getprop ro.product.cpu.abi)

ui_print "  [i] Platform: $SOC"
ui_print "  [i] Hardware: $SOC_MANUF"

# Determine SoC type
if echo "$SOC" | grep -qi "mt"; then
    SOC_TYPE="mediatek"
    ui_print "  [+] MediaTek device detected"
elif echo "$SOC" | grep -qiE "sm[0-9]+|sdm[0-9]+|msm[0-9]+|kona|lito|bengal|lahaina|taro|kalama|pineapple"; then
    SOC_TYPE="qualcomm"
    ui_print "  [+] Qualcomm Snapdragon device detected"
elif echo "$SOC_MANUF" | grep -qi "mediatek"; then
    SOC_TYPE="mediatek"
    ui_print "  [+] MediaTek device detected (via hardware)"
elif echo "$SOC_MANUF" | grep -qi "qcom"; then
    SOC_TYPE="qualcomm"
    ui_print "  [+] Qualcomm Snapdragon device detected (via hardware)"
else
    SOC_TYPE="generic"
    ui_print "  [!] Unknown SoC, applying generic tweaks"
fi

# Save detection
echo "$SOC_TYPE" > $MODDIR/soc_type.conf

ui_print " "
ui_print "  [i] Installing Auria Tweak..."
ui_print " "

ui_print "  [+] Applying ${SOC_TYPE} tweaks..."
ui_print "  [i] Features:"
ui_print "      - Disable thermal throttling"
ui_print "      - Optimize charging"
ui_print "      - Optimize display"
ui_print "      - Optimize rendering"
ui_print " "

if [ -f "$MODDIR/soc_type.conf" ]; then
    ui_print "  [✓] Installation complete!"
else
    ui_print "  [!] Installation warning"
fi
ui_print " "
