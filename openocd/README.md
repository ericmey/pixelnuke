# OpenOCD Configuration for Pixelnuke

OpenOCD configurations for debugging Pi Zero 2 W via SWD.

## Hardware Setup

### Raspberry Pi Debug Probe Connections

| Debug Probe | Pi Zero 2 W | Header Pin |
|-------------|-------------|------------|
| SWCLK       | GPIO25      | Pin 22     |
| SWDIO       | GPIO24      | Pin 18     |
| GND         | GND         | Pin 6      |

Optional UART (for serial bootloader):

| Debug Probe | Pi Zero 2 W | Header Pin |
|-------------|-------------|------------|
| UART TX     | GPIO15 (RX) | Pin 10     |
| UART RX     | GPIO14 (TX) | Pin 8      |
| GND         | GND         | Pin 6      |

## Quick Start

```bash
# From project root, start OpenOCD
openocd -f openocd/rpi-debug-probe.cfg

# In another terminal, connect with GDB (64-bit)
aarch64-none-elf-gdb -ex "target extended-remote :3333" src/bootloader/kernel8.elf

# Or use telnet for direct OpenOCD commands
telnet localhost 4444
```

## Useful OpenOCD Commands

```tcl
# Halt the CPU
halt

# Show CPU state
reg

# Read memory
mdw 0x8000 16

# Resume execution
resume

# Reset the target
reset

# Step one instruction
step
```

## Configuration Files

- `rpi-debug-probe.cfg` - Main config for Debug Probe + Pi Zero 2 W
- `interface/raspberrypi-debug-probe.cfg` - Debug Probe interface settings
- `board/rpi-zero2w.cfg` - Pi Zero 2 W board definition
- `target/bcm2710.cfg` - BCM2710/BCM2837 target (Cortex-A53)

## Troubleshooting

### "Error: unable to find a matching CMSIS-DAP device"

- Check USB connection
- Verify Debug Probe has correct firmware
- Try `lsusb` (Linux) or `system_profiler SPUSBDataType` (macOS)

### "Error: Failed to connect multidrop rpi.cpu"

- Check SWD wiring (SWCLK, SWDIO, GND)
- Ensure Pi is powered
- Try reducing adapter speed: `adapter speed 100`

### "Error: expected id 0x4ba00477"

- This is the ARM DAP ID, should match
- If different ID appears, wiring may be wrong
