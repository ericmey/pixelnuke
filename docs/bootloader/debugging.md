# Debugging

This guide covers debugging techniques for the Pixelnuke bootloader.

## Serial Console

The serial console is your primary debugging tool.

### Hardware Setup

**Raspberry Pi Debug Probe (recommended):**
```
Debug Probe         Pi Zero 2 W
────────────        ────────────
UART TX     →       GPIO15 (pin 10, RX)
UART RX     ←       GPIO14 (pin 8, TX)
GND         ─       GND
```

**Other USB-Serial adapters (FT232R, CH340, etc.):**
Same wiring, ensure 3.3V logic levels (not 5V).

### Connecting

```bash
# Find your serial device
ls /dev/tty.usb*          # macOS
ls /dev/ttyUSB* /dev/ttyACM*  # Linux

# Connect with screen
screen /dev/tty.usbmodem14101 115200

# Or with minicom
minicom -D /dev/tty.usbmodem14101 -b 115200

# Exit screen: Ctrl-A, then K, then Y
# Exit minicom: Ctrl-A, then X
```

### Normal Boot Output

```
Pixelnuke Bootloader
Compile time: Jan 31 2025 19:31:00
Current partition: A
Waiting 2 seconds for serial upload...
Connecting to WiFi...
Network up: 192.168.1.100
TFTP: tftp -m binary 192.168.1.100 -c put pxnk_pixelnuke_kernel.img
Starting TFTP server...
Waiting for firmware upload...
```

## Common Issues

### No Serial Output

**Symptoms:** Nothing appears on serial console after power-on.

**Causes & Solutions:**

1. **Wrong baud rate**
   - Must be 115200 baud
   - Check your terminal settings

2. **TX/RX swapped**
   - Try swapping TX and RX wires
   - Debug Probe TX → Pi RX (GPIO15)

3. **Kernel not loading**
   - Check `kernel8.img` exists on boot partition
   - Verify `config.txt` has `arm_64bit=1`

4. **Power issue**
   - Pi Zero 2 W needs stable 5V supply
   - Try a different USB cable/power source

### WiFi Connection Fails

**Symptoms:** Serial shows "WiFi connection timeout" or "WLAN init failed"

**Check wpa_supplicant.conf:**
```
# Must have correct structure
country=US

network={
    ssid="ExactSSIDHere"
    psk="ExactPasswordHere"
    proto=WPA2
    key_mgmt=WPA-PSK
}
```

**Common mistakes:**
- Wrong SSID (case-sensitive)
- Wrong password
- Missing country code
- File saved with wrong encoding (must be UTF-8, LF line endings)

**Check firmware files exist:**
```
ls firmware/
# Should see:
# brcmfmac43430-sdio.bin
# brcmfmac43430-sdio.txt
# brcmfmac43430-sdio.clm_blob
```

### Boot Loop

**Symptoms:** Pi continuously reboots every few seconds.

**Causes:**

1. **Kernel crash**
   - Check serial output for crash messages
   - May see "Kernel panic" or assertion failures

2. **Missing kernel**
   - Verify `kernel8.img` exists and isn't empty
   - Check file size: should be ~800KB for bootloader

3. **Config.txt issue**
   - Verify `arm_64bit=1` is set
   - Check for syntax errors

### Partition Detection Fails

**Symptoms:** "Could not detect partition, assuming A"

**Cause:** Missing `.partition_id` file on boot partition.

**Fix:**
```bash
# On PXNK_A:
echo "A" > /Volumes/PXNK_A/.partition_id

# On PXNK_B:
echo "B" > /Volumes/PXNK_B/.partition_id
```

## SWD Debugging (Advanced)

For low-level debugging with GDB, use the Debug Probe's SWD interface.

### Wiring
```
Debug Probe         Pi Zero 2 W
────────────        ────────────
SWCLK       →       GPIO25 (pin 22)
SWDIO       ↔       GPIO24 (pin 18)
GND         ─       GND
```

### OpenOCD

```bash
# Start OpenOCD
openocd -f openocd/rpi-debug-probe.cfg

# In another terminal, connect GDB
aarch64-none-elf-gdb src/bootloader/kernel8.elf
(gdb) target remote :3333
(gdb) monitor reset halt
(gdb) break main
(gdb) continue
```

### Useful GDB Commands

```gdb
# Show registers
info registers

# Show call stack
backtrace

# Read memory
x/10x 0x80000

# Set breakpoint
break CKernel::Run

# Continue execution
continue

# Step over
next

# Step into
step
```

## Log Levels

The bootloader uses Circle's logging system with these levels:

| Level | Description |
|-------|-------------|
| LogPanic | Fatal errors, system halts |
| LogError | Errors that prevent operation |
| LogWarning | Non-fatal issues |
| LogNotice | Important status messages |
| LogDebug | Detailed debugging info |

Default level shows LogNotice and above. To see debug messages, modify `cmdline.txt`:
```
loglevel=4
```

## Performance Issues

### Slow WiFi Connection

WiFi typically connects in 5-15 seconds. If it takes longer:
1. Check signal strength (move closer to router)
2. Try a less congested WiFi channel
3. Verify router supports 2.4GHz (Pi Zero 2 W doesn't support 5GHz)

### TFTP Transfer Slow

TFTP is intentionally simple, not fast. For ~800KB bootloader:
- Expected: 2-5 seconds on good connection
- If slower: check network congestion

## Getting Help

1. Check serial console output first
2. Review this documentation
3. Check GitHub issues for similar problems
4. Open new issue with:
   - Serial console output
   - Hardware setup description
   - Steps to reproduce
