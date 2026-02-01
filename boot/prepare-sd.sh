#!/bin/bash
# Prepare SD card for Pixelnuke bootloader
# Usage: ./prepare-sd.sh /Volumes/SDCARD
#
# This script sets up the SD card with:
# - GPU boot firmware (bootcode.bin, start.elf, fixup.dat)
# - Device tree blob for Pi Zero 2 W
# - Pixelnuke bootloader as kernel8.img (64-bit)
# - WiFi firmware files (BCM43436/SYN43436)
# - Example wpa_supplicant.conf

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CIRCLE_BOOT="$PROJECT_DIR/circle/boot"
CIRCLE_WLAN_FW="$PROJECT_DIR/circle/addon/wlan/firmware"
BOOTLOADER_DIR="$PROJECT_DIR/src/bootloader"

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

echo "==================================="
echo "Pixelnuke SD Card Preparation"
echo "==================================="
echo ""
echo "Target: $SD_CARD"
echo ""

# Copy boot firmware
echo "1. Copying GPU boot firmware..."
cp "$CIRCLE_BOOT/bootcode.bin" "$SD_CARD/"
cp "$CIRCLE_BOOT/start.elf" "$SD_CARD/"
cp "$CIRCLE_BOOT/fixup.dat" "$SD_CARD/"
cp "$CIRCLE_BOOT/bcm2710-rpi-zero-2-w.dtb" "$SD_CARD/"

# Create config.txt for Pi Zero 2 W (64-bit mode)
echo "2. Creating config.txt..."
cat > "$SD_CARD/config.txt" << 'EOF'
# Pixelnuke bootloader configuration
# Pi Zero 2 W - BCM2710A1 (64-bit mode)
# WiFi: Synaptics SYN43436 (BCM43436)

# Enable UART for serial console/bootloader
enable_uart=1
core_freq=250

# I2S audio for PCM5100A DAC (Pimoroni Pirate Audio)
dtparam=i2s=on
dtoverlay=hifiberry-dac

# SPI for ST7789 display
dtparam=spi=on

# Disable unused interfaces
dtparam=i2c_arm=off
dtparam=audio=off

# kernel8.img is loaded by default for Pi 3/Zero 2 W in 64-bit mode
EOF

# Create cmdline.txt
echo "3. Creating cmdline.txt..."
cat > "$SD_CARD/cmdline.txt" << 'EOF'
sounddev=sndi2s logdev=ttyS1
EOF

# Copy bootloader if it exists
if [ -f "$BOOTLOADER_DIR/kernel8.img" ]; then
    echo "4. Copying bootloader kernel (kernel8.img)..."
    cp "$BOOTLOADER_DIR/kernel8.img" "$SD_CARD/"
else
    echo "4. Bootloader not built yet - skipping kernel8.img"
    echo "   Build with: cd src/bootloader && make"
fi

# Create firmware directory and copy WiFi firmware
# Pi Zero 2 W uses SYN43436 which needs brcmfmac43436-sdio.* files
echo "5. Setting up WiFi firmware (SYN43436/BCM43436)..."
mkdir -p "$SD_CARD/firmware"
if [ -d "$CIRCLE_WLAN_FW" ] && [ -n "$(ls -A $CIRCLE_WLAN_FW/*.bin 2>/dev/null)" ]; then
    cp "$CIRCLE_WLAN_FW"/*.bin "$SD_CARD/firmware/" 2>/dev/null || true
    cp "$CIRCLE_WLAN_FW"/*.txt "$SD_CARD/firmware/" 2>/dev/null || true
    cp "$CIRCLE_WLAN_FW"/*.clm_blob "$SD_CARD/firmware/" 2>/dev/null || true
    echo "   Copied WiFi firmware files"
    # List the specific files needed for Zero 2 W
    if [ -f "$SD_CARD/firmware/brcmfmac43436-sdio.bin" ]; then
        echo "   Found brcmfmac43436-sdio.* (required for Zero 2 W)"
    fi
else
    echo "   WiFi firmware not downloaded yet"
    echo "   Download with: make wifi-firmware"
fi

# Create example wpa_supplicant.conf
echo "6. Creating wpa_supplicant.conf.example..."
cat > "$SD_CARD/wpa_supplicant.conf.example" << 'EOF'
# WiFi configuration for Pixelnuke bootloader
# Copy this file to wpa_supplicant.conf and edit with your credentials
#
# Uncomment country code for your region (optional)
#country=US

network={
    ssid="YourNetworkName"
    psk="YourPassword"
    proto=WPA2
    key_mgmt=WPA-PSK
}
EOF

# Check if user already has a wpa_supplicant.conf
if [ ! -f "$SD_CARD/wpa_supplicant.conf" ]; then
    echo "   (No wpa_supplicant.conf found - WiFi will be disabled)"
else
    echo "   Found existing wpa_supplicant.conf - preserving"
fi

echo ""
echo "==================================="
echo "SD card preparation complete!"
echo "==================================="
echo ""
echo "Files on SD card:"
ls -la "$SD_CARD"/ 2>/dev/null | head -20
echo ""
if [ -d "$SD_CARD/firmware" ]; then
    echo "WiFi firmware files:"
    ls "$SD_CARD/firmware/"*.bin 2>/dev/null | head -5 || echo "  (none)"
    echo ""
fi

echo "Next steps:"
echo ""
echo "1. Build the bootloader (if not done):"
echo "   make bootloader"
echo "   cp src/bootloader/kernel8.img $SD_CARD/"
echo ""
echo "2. Configure WiFi (optional but recommended):"
echo "   cp $SD_CARD/wpa_supplicant.conf.example $SD_CARD/wpa_supplicant.conf"
echo "   Edit with your network credentials"
echo ""
echo "3. Download WiFi firmware (if not done):"
echo "   make wifi-firmware"
echo ""
echo "4. Insert SD card and power on Pi Zero 2 W"
echo ""
echo "5. Connect via:"
echo "   - Serial: ./flash.sh firmware.img"
echo "   - HTTP:   http://<pi-ip>:8080/"
echo "   - TFTP:   tftp -m binary <pi-ip> -c put firmware.img"
