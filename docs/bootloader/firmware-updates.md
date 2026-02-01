# Firmware Updates

Pixelnuke supports two methods for firmware updates:
1. **Serial Upload** - Fast, for development
2. **TFTP Upload** - WiFi-based, for field deployment

## Serial Upload (Development)

Serial upload is the fastest method for development iteration.

### Requirements
- USB-to-Serial adapter (Debug Probe, FT232R, etc.)
- Connection to Pi's UART pins

### Wiring
```
USB-Serial Adapter    Pi Zero 2 W
──────────────────    ────────────
TX          →         GPIO15 (pin 10, RX)
RX          ←         GPIO14 (pin 8, TX)
GND         ─         GND
```

### Using flash.sh
```bash
# Build and flash in one command
./flash.sh

# Or manually:
make -C src/bootloader
./circle/tools/flashy/flashy /dev/tty.usbmodem* src/bootloader/kernel8.img
```

### Protocol
1. Bootloader sends `IHEX-F\r\n` on startup
2. Host tool detects this and initiates transfer
3. Firmware uploads in ~2-3 seconds
4. Bootloader reboots with new firmware

## TFTP Upload (WiFi OTA)

TFTP provides wireless firmware updates for deployed devices.

### Requirements
- WiFi configured in `wpa_supplicant.conf`
- TFTP client on your computer
- Network connectivity to the Pi

### Finding the IP Address

Check the serial console output:
```
Network up: 192.168.1.100
TFTP: tftp -m binary 192.168.1.100 -c put pxnk_pixelnuke_kernel.img
```

Or check your router's DHCP client list for hostname `pixelnuke`.

### Upload Command

**Important:** Files must use the authentication prefix `pxnk_pixelnuke_`.

```bash
# Rename your firmware
cp kernel8.img pxnk_pixelnuke_kernel.img

# Upload via TFTP
tftp -m binary 192.168.1.100 -c put pxnk_pixelnuke_kernel.img
```

### macOS TFTP
```bash
tftp 192.168.1.100
tftp> mode binary
tftp> put pxnk_pixelnuke_kernel.img
tftp> quit
```

### Linux TFTP
```bash
tftp 192.168.1.100 << EOF
binary
put pxnk_pixelnuke_kernel.img
quit
EOF
```

## A/B Partition Update Flow

When firmware is uploaded via TFTP:

```
1. Bootloader receives firmware
   └─ Validates file prefix (pxnk_pixelnuke_)
   └─ Buffers in RAM

2. Writes to alternate partition
   └─ If booted from A → writes to B
   └─ If booted from B → writes to A

3. Sets tryboot flag
   └─ Via GPU mailbox property 0x00038064

4. Reboots
   └─ GPU reads autoboot.txt
   └─ tryboot flag → boots alternate partition

5. New firmware runs
   └─ If successful: becomes new default
   └─ If fails: next boot reverts to previous
```

## Security

### Authentication Prefix
TFTP files must start with `pxnk_pixelnuke_` to be accepted. This prevents:
- Accidental uploads from other TFTP traffic
- Unauthorized firmware uploads (basic protection)

**Note:** This is not cryptographic security. For production deployments, consider:
- VPN/firewall isolation
- Signed firmware images (future enhancement)

### Rejected Uploads
Files without the correct prefix are rejected:
```
tftpboot: Rejected file: wrong_name.img (invalid prefix)
```

## Troubleshooting

### Serial upload not detected
1. Check wiring (TX→RX, RX→TX)
2. Verify baud rate: 115200
3. Check serial device path: `ls /dev/tty.*`

### TFTP upload fails
1. Verify WiFi is connected (check serial console)
2. Check IP address is correct
3. Ensure filename has correct prefix
4. Try `ping` to verify connectivity

### Firmware doesn't boot after update
1. Wait ~30 seconds for automatic rollback
2. Check serial console for error messages
3. If stuck, manually restore via SD card

### "Firmware too large" error
Maximum firmware size is defined by `KERNEL_MAX_SIZE`. Current limit handles typical bootloader/application sizes. Contact maintainers if you need larger images.

## Next Steps

- [Debugging](debugging.md) - Serial console and troubleshooting
- [Architecture](architecture.md) - Technical details
