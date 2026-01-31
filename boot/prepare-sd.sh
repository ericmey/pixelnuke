#!/bin/bash
# Prepare SD card files for Pi Zero 2 W serial bootloader setup
# Usage: ./prepare-sd.sh /Volumes/SDCARD

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CIRCLE_BOOT="$PROJECT_DIR/circle/boot"
CIRCLE_BOOTLOADER="$PROJECT_DIR/circle/tools/bootloader"

if [ -z "$1" ]; then
    echo "Usage: $0 <sd-card-mount-point>"
    echo "Example: $0 /Volumes/BOOT"
    exit 1
fi

SD_CARD="$1"

if [ ! -d "$SD_CARD" ]; then
    echo "Error: $SD_CARD is not a valid directory"
    exit 1
fi

echo "Preparing SD card at: $SD_CARD"
echo ""

# Copy boot firmware
echo "Copying boot firmware..."
cp "$CIRCLE_BOOT/bootcode.bin" "$SD_CARD/"
cp "$CIRCLE_BOOT/start.elf" "$SD_CARD/"
cp "$CIRCLE_BOOT/fixup.dat" "$SD_CARD/"
cp "$CIRCLE_BOOT/bcm2710-rpi-zero-2-w.dtb" "$SD_CARD/"

# Copy config for 32-bit mode
echo "Copying config.txt (32-bit mode)..."
cp "$CIRCLE_BOOT/config32.txt" "$SD_CARD/config.txt"

# Copy bootloader kernel
echo "Copying serial bootloader (kernel7.img)..."
cp "$CIRCLE_BOOTLOADER/kernel7.img" "$SD_CARD/"

# Create minimal cmdline.txt
echo "Creating cmdline.txt..."
cat > "$SD_CARD/cmdline.txt" << 'EOF'
sounddev=sndi2s logdev=ttyS1
EOF

echo ""
echo "SD card prepared successfully!"
echo ""
echo "Files copied:"
ls -la "$SD_CARD"/*.bin "$SD_CARD"/*.elf "$SD_CARD"/*.dat "$SD_CARD"/*.img "$SD_CARD"/*.txt "$SD_CARD"/*.dtb 2>/dev/null || true
echo ""
echo "Next steps:"
echo "1. Insert SD card into Pi Zero 2 W"
echo "2. Connect Xiao RP2040 serial bridge"
echo "3. Power on Pi - bootloader will wait for kernel upload"
echo "4. Use: ./flash.sh /dev/cu.usbmodem* src/kernel8-32.img"
