#!/bin/bash
# Flash firmware to Pi Zero 2 W via serial bootloader
#
# Usage:
#   ./flash.sh [serial-port] [firmware.img]
#
# Examples:
#   ./flash.sh                                    # Auto-detect port, flash bootloader
#   ./flash.sh /dev/tty.usbmodem*                 # Specify port, flash bootloader
#   ./flash.sh /dev/tty.usbmodem* src/app/kernel8.img  # Flash specific firmware
#
# This script uses Circle's cflashy tool to upload firmware via the
# serial bootloader protocol (IHEX-F).

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CFLASHY="$SCRIPT_DIR/circle/tools/cflashy"
FLASHY="$SCRIPT_DIR/circle/tools/flashy/flashy.js"

# Default settings
BAUD=115200
DEFAULT_FIRMWARE="$SCRIPT_DIR/src/bootloader/kernel8.img"
LOAD_ADDR=0x80000  # 64-bit load address

# Parse arguments
SERIAL_PORT=""
FIRMWARE=""

for arg in "$@"; do
    if [[ "$arg" == /dev/* ]] || [[ "$arg" == COM* ]]; then
        # Expand glob pattern for serial port
        SERIAL_PORT=$(echo $arg)
    elif [[ "$arg" == *.img ]] || [[ "$arg" == *.hex ]]; then
        FIRMWARE="$arg"
    fi
done

# Auto-detect serial port if not specified
if [ -z "$SERIAL_PORT" ]; then
    # Try common serial device patterns
    if [ "$(uname)" == "Darwin" ]; then
        # macOS - try Debug Probe, then other USB serial devices
        SERIAL_PORT=$(ls /dev/tty.usbmodem* 2>/dev/null | head -1 || true)
        if [ -z "$SERIAL_PORT" ]; then
            SERIAL_PORT=$(ls /dev/tty.usbserial* 2>/dev/null | head -1 || true)
        fi
        if [ -z "$SERIAL_PORT" ]; then
            SERIAL_PORT=$(ls /dev/cu.usbmodem* 2>/dev/null | head -1 || true)
        fi
    else
        # Linux
        SERIAL_PORT=$(ls /dev/ttyACM* 2>/dev/null | head -1 || true)
        if [ -z "$SERIAL_PORT" ]; then
            SERIAL_PORT=$(ls /dev/ttyUSB* 2>/dev/null | head -1 || true)
        fi
    fi

    if [ -z "$SERIAL_PORT" ]; then
        echo "Error: No serial port found"
        echo ""
        echo "Available ports:"
        if [ "$(uname)" == "Darwin" ]; then
            ls /dev/tty.usb* /dev/cu.usb* 2>/dev/null || echo "  (none)"
        else
            ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || echo "  (none)"
        fi
        echo ""
        echo "Usage: $0 [serial-port] [firmware.img]"
        exit 1
    fi
fi

# Use default firmware if not specified
if [ -z "$FIRMWARE" ]; then
    FIRMWARE="$DEFAULT_FIRMWARE"
fi

# Check if firmware exists
if [ ! -f "$FIRMWARE" ]; then
    echo "Error: Firmware file not found: $FIRMWARE"
    echo ""
    echo "Build the bootloader first:"
    echo "  make bootloader"
    exit 1
fi

echo "==================================="
echo "Pixelnuke Serial Flash"
echo "==================================="
echo ""
echo "Port:     $SERIAL_PORT"
echo "Firmware: $FIRMWARE"
echo "Size:     $(wc -c < "$FIRMWARE" | tr -d ' ') bytes"
echo ""

# Convert .img to .hex if needed
HEX_FILE="$FIRMWARE"
if [[ "$FIRMWARE" == *.img ]]; then
    HEX_FILE="${FIRMWARE%.img}.hex"
    if [ ! -f "$HEX_FILE" ] || [ "$FIRMWARE" -nt "$HEX_FILE" ]; then
        echo "Converting to Intel HEX format (load address: $LOAD_ADDR)..."
        aarch64-none-elf-objcopy -I binary -O ihex --change-addresses $LOAD_ADDR "$FIRMWARE" "$HEX_FILE"
    fi
fi

echo "Waiting for bootloader..."
echo "(Power cycle Pi if needed)"
echo ""

# Prefer cflashy (native) if available, otherwise use node flashy
if [ -x "$CFLASHY" ]; then
    "$CFLASHY" "$SERIAL_PORT" --flashBaud:$BAUD "$HEX_FILE"
elif [ -f "$FLASHY" ]; then
    node "$FLASHY" "$SERIAL_PORT" --flashBaud:$BAUD "$HEX_FILE"
else
    echo "Error: Neither cflashy nor flashy.js found"
    echo "Build cflashy: cd circle/tools && make"
    exit 1
fi

echo ""
echo "Flash complete!"
