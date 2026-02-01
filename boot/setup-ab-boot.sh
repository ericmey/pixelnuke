#!/bin/bash
#
# Set up A/B boot structure for Pixelnuke
#
# Partition layout:
#   PXNK_BOOT: GPU firmware, autoboot.txt, WiFi config (static, never updated OTA)
#   PXNK_A:    Kernel slot A (updated via OTA)
#   PXNK_B:    Kernel slot B (updated via OTA)
#   PXNK_USER: User data (samples, projects)
#
# Usage:
#   ./setup-ab-boot.sh <PXNK_BOOT> <PXNK_A> <PXNK_B>
#
# Example:
#   ./setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 <PXNK_BOOT> <PXNK_A> <PXNK_B>"
    echo ""
    echo "Example:"
    echo "  $0 /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B"
    exit 1
fi

BOOT_SEL="$1"
BOOT_A="$2"
BOOT_B="$3"

# Verify partitions exist
for part in "$BOOT_SEL" "$BOOT_A" "$BOOT_B"; do
    if [ ! -d "$part" ]; then
        echo "ERROR: $part is not mounted or does not exist"
        exit 1
    fi
done

echo "========================================"
echo "Pixelnuke A/B Boot Setup"
echo "========================================"
echo ""
echo "Boot selector: $BOOT_SEL"
echo "Boot A:        $BOOT_A"
echo "Boot B:        $BOOT_B"
echo ""

# Check for required files
KERNEL_IMG="$PROJECT_ROOT/src/bootloader/kernel8.img"
if [ ! -f "$KERNEL_IMG" ]; then
    echo "ERROR: Bootloader not built. Run 'make -C src/bootloader' first."
    echo "Expected: $KERNEL_IMG"
    exit 1
fi

CIRCLE_BOOT="$PROJECT_ROOT/circle/boot"
if [ ! -d "$CIRCLE_BOOT" ]; then
    echo "ERROR: Circle boot files not found at $CIRCLE_BOOT"
    exit 1
fi

WIFI_FW="$PROJECT_ROOT/circle/addon/wlan/firmware"
if [ ! -d "$WIFI_FW" ]; then
    echo "ERROR: WiFi firmware not found. Run 'make wifi-firmware' first."
    exit 1
fi

# ============================================
# PXNK_BOOT - Static configuration partition
# ============================================
echo "Setting up PXNK_BOOT (static config)..."

# GPU firmware (required to boot)
echo "  Copying GPU firmware..."
cp "$CIRCLE_BOOT/bootcode.bin" "$BOOT_SEL/"
cp "$CIRCLE_BOOT/start.elf" "$BOOT_SEL/"
cp "$CIRCLE_BOOT/fixup.dat" "$BOOT_SEL/"

# A/B boot selector
echo "  Creating autoboot.txt..."
cat > "$BOOT_SEL/autoboot.txt" << 'EOF'
# Pixelnuke A/B Boot Selector
#
# Normal boot: Partition 2 (Boot A)
# Tryboot:     Partition 3 (Boot B)
#
# To trigger tryboot, use mailbox property 0x00038064
# or reboot with "0 tryboot" argument

[all]
tryboot_a_b=1
boot_partition=2

[tryboot]
boot_partition=3
EOF

# WiFi firmware (static, doesn't change with OTA)
echo "  Copying WiFi firmware..."
mkdir -p "$BOOT_SEL/firmware"
cp "$WIFI_FW"/brcmfmac43430-sdio.* "$BOOT_SEL/firmware/" 2>/dev/null || true
cp "$WIFI_FW"/brcmfmac43436-sdio.* "$BOOT_SEL/firmware/" 2>/dev/null || true
cp "$WIFI_FW"/brcmfmac43436s-sdio.* "$BOOT_SEL/firmware/" 2>/dev/null || true

# WiFi config template (user edits this once)
echo "  Creating wpa_supplicant.conf template..."
cat > "$BOOT_SEL/wpa_supplicant.conf" << 'WPAEOF'
# WiFi configuration for Pixelnuke
# Edit this file with your WiFi credentials
country=US

network={
    ssid="YourNetworkName"
    psk="YourPassword"
    proto=WPA2
    key_mgmt=WPA-PSK
}
WPAEOF

echo "  Done with PXNK_BOOT"

# ============================================
# PXNK_A and PXNK_B - Kernel partitions
# ============================================
setup_kernel_partition() {
    local DEST="$1"
    local NAME="$2"
    local PARTITION_ID="$3"

    echo ""
    echo "Setting up $NAME at $DEST..."

    # Device tree (needed by GPU to configure hardware)
    echo "  Copying device tree..."
    cp "$CIRCLE_BOOT/bcm2710-rpi-zero-2-w.dtb" "$DEST/"

    # Kernel
    echo "  Copying kernel..."
    cp "$KERNEL_IMG" "$DEST/kernel8.img"

    # Config for this partition
    echo "  Creating config.txt..."
    cat > "$DEST/config.txt" << 'CONFIGEOF'
# Pixelnuke - Pi Zero 2 W Configuration

# Enable UART for serial console/bootloader
enable_uart=1
core_freq=250

# I2S audio for PCM5100A DAC
dtparam=i2s=on
dtoverlay=hifiberry-dac

# SPI for ST7789 display
dtparam=spi=on

# Disable unused interfaces
dtparam=i2c_arm=off
dtparam=audio=off

# 64-bit mode
arm_64bit=1
CONFIGEOF

    # Kernel command line
    echo "  Creating cmdline.txt..."
    echo "sounddev=sndi2s logdev=ttyS1" > "$DEST/cmdline.txt"

    # Partition identifier
    echo "$PARTITION_ID" > "$DEST/.partition_id"

    # Boot counter for rollback detection
    echo "0" > "$DEST/bootcount"

    # Factory content placeholder (read-only content bundled with firmware)
    echo "  Creating factory content structure..."
    mkdir -p "$DEST/factory/samples"
    mkdir -p "$DEST/factory/presets"
    mkdir -p "$DEST/factory/kits"
    echo "# Factory samples go here (read-only)" > "$DEST/factory/samples/.gitkeep"
    echo "# Factory presets go here (read-only)" > "$DEST/factory/presets/.gitkeep"
    echo "# Factory kits go here (read-only)" > "$DEST/factory/kits/.gitkeep"

    echo "  Done with $NAME"
}

setup_kernel_partition "$BOOT_A" "Boot A" "A"
setup_kernel_partition "$BOOT_B" "Boot B" "B"

echo ""
echo "========================================"
echo "A/B Boot Setup Complete!"
echo "========================================"
echo ""
echo "Partition layout:"
echo "  PXNK_BOOT: GPU firmware, WiFi config (static)"
echo "  PXNK_A:    Kernel slot A (default)"
echo "  PXNK_B:    Kernel slot B (OTA updates)"
echo "  PXNK_USER: User data"
echo ""
echo "Next steps:"
echo "  1. Edit wpa_supplicant.conf on PXNK_BOOT with your WiFi credentials"
echo "  2. Eject SD card and insert into Pi Zero 2 W"
echo "  3. Power on - bootloader will start from partition A"
echo ""
echo "OTA Update flow:"
echo "  1. Upload firmware via TFTP to bootloader"
echo "  2. Bootloader writes to inactive partition (A→B or B→A)"
echo "  3. Bootloader sets tryboot flag and reboots"
echo "  4. GPU boots from new partition"
echo "  5. If successful, new partition becomes default"
echo ""
