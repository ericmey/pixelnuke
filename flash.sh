#!/bin/bash
# Flash kernel to Pi via serial bootloader
# Usage: ./flash.sh [serial-device] [kernel-image]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLASHY="$SCRIPT_DIR/circle/tools/flashy/flashy.js"
CFLASHY="$SCRIPT_DIR/circle/tools/cflashy"

# Default device - try to find it
if [ -z "$1" ]; then
    DEVICE=$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)
    if [ -z "$DEVICE" ]; then
        echo "Error: No USB serial device found"
        echo "Usage: $0 <serial-device> [kernel-image]"
        echo "Example: $0 /dev/cu.usbmodem14101 src/kernel8-32.img"
        exit 1
    fi
else
    DEVICE="$1"
fi

# Default kernel
KERNEL="${2:-$SCRIPT_DIR/src/kernel8-32.img}"

if [ ! -f "$KERNEL" ]; then
    echo "Error: Kernel image not found: $KERNEL"
    echo "Build the project first with: make"
    exit 1
fi

echo "Flashing: $KERNEL"
echo "Device:   $DEVICE"
echo ""

# Prefer cflashy (native) if available, otherwise use node flashy
if [ -x "$CFLASHY" ]; then
    "$CFLASHY" "$DEVICE" "$KERNEL"
else
    node "$FLASHY" "$DEVICE" "$KERNEL"
fi
