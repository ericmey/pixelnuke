# Bootloader Overview

The Pixelnuke bootloader is a minimal firmware update system that runs on the Raspberry Pi Zero 2 W before the main application. It enables:

- **Fast serial uploads** for development (~2-3 seconds)
- **WiFi OTA updates** via TFTP for field deployment
- **A/B partition scheme** for safe, rollback-capable updates

## Boot Flow

```
Power On
    │
    ▼
┌─────────────────────────────────────┐
│         GPU Firmware                │
│  (bootcode.bin, start.elf)          │
│                                     │
│  Reads autoboot.txt to select       │
│  partition A or B                   │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│         Bootloader                  │
│      (kernel8.img)                  │
│                                     │
│  1. Initialize serial (115200)      │
│  2. Send "IHEX-F\r\n" ready signal  │
│  3. Wait 2s for serial upload       │
│  4. Connect to WiFi (if configured) │
│  5. Start TFTP server (port 69)     │
│  6. Wait for firmware upload        │
│  7. Write to alternate partition    │
│  8. Set tryboot flag, reboot        │
└─────────────────────────────────────┘
```

## Key Features

### Serial Bootloader Protocol
The bootloader sends `IHEX-F\r\n` on startup, compatible with Circle's `flashy` and `cflashy` tools. This enables rapid iteration during development without removing the SD card.

### A/B Partition Scheme
Uses the Raspberry Pi GPU firmware's native tryboot mechanism:
- Partition A: Default boot partition
- Partition B: Update target partition
- On successful update: new partition becomes default
- On boot failure: automatic rollback to previous partition

### TFTP Firmware Upload
When WiFi is configured, the bootloader listens on port 69 for TFTP uploads. Files must use the authentication prefix:
```
pxnk_pixelnuke_<filename>.img
```

### Security
- TFTP requires filename prefix authentication
- No remote code execution without valid prefix
- WiFi credentials stored locally on SD card

## Next Steps

- [SD Card Setup](sd-card-setup.md) - Prepare your SD card
- [Firmware Updates](firmware-updates.md) - Upload new firmware
- [Debugging](debugging.md) - Troubleshoot issues
