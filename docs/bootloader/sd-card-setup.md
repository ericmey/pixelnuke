# SD Card Setup

This guide covers preparing an SD card for Pixelnuke with A/B partition support.

## Requirements

- microSD card (8GB minimum, 16GB+ recommended)
- SD card reader
- macOS, Linux, or Windows computer

## Partition Layout

```
┌──────────────────────────────────────────────────────────┐
│  Partition 1: PXNK_BOOT (256MB)                          │
│  Boot selector with autoboot.txt                         │
├──────────────────────────────────────────────────────────┤
│  Partition 2: PXNK_A (1GB)                               │
│  Boot A - Primary boot partition                         │
├──────────────────────────────────────────────────────────┤
│  Partition 3: PXNK_B (1GB)                               │
│  Boot B - Update target partition                        │
├──────────────────────────────────────────────────────────┤
│  Partition 4: PXNK_USER (remaining space)                │
│  User data - samples, projects, settings                 │
└──────────────────────────────────────────────────────────┘
```

## Step 1: Find Your SD Card Device

**macOS:**
```bash
diskutil list
```
Look for your SD card (external, ~8-32GB). It will be something like `/dev/disk4`.

**Linux:**
```bash
lsblk
```
Look for your SD card (e.g., `/dev/sdb` or `/dev/mmcblk0`).

**Warning:** Make sure you identify the correct disk. Partitioning the wrong disk will erase your data!

## Step 2: Partition the SD Card

**Warning: This will erase all data on the SD card.**

The partition script auto-detects your OS and uses the appropriate tool:

```bash
# This works on both macOS and Linux
./boot/partition-sd.sh /dev/diskN   # Replace with your device
```

Or use the OS-specific scripts directly:

```bash
# macOS (uses diskutil)
./tools/macos/partition-sd.sh /dev/disk4

# Linux (uses fdisk)
./tools/linux/partition-sd.sh /dev/sdb
```

The script will:
1. Ask you to confirm by typing `YES`
2. Create MBR partition table (required for Pi's tryboot feature)
3. Create 4 FAT32 partitions with correct sizes
4. Format and label each partition

After completion, the partitions should auto-mount:
- macOS: Check `/Volumes/` for PXNK_BOOT, PXNK_A, PXNK_B, PXNK_USER
- Linux: Check your file manager or mount manually

## Step 3: Set Up A/B Boot

Run the setup script to populate the boot partitions:

**macOS:**
```bash
./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B
```

**Linux:**
```bash
# Mount partitions first if not auto-mounted
sudo mkdir -p /mnt/{pxnk_boot,pxnk_a,pxnk_b}
sudo mount /dev/sdb1 /mnt/pxnk_boot
sudo mount /dev/sdb2 /mnt/pxnk_a
sudo mount /dev/sdb3 /mnt/pxnk_b

./boot/setup-ab-boot.sh /mnt/pxnk_boot /mnt/pxnk_a /mnt/pxnk_b
```

This script:
1. Creates `autoboot.txt` on the boot selector partition
2. Copies GPU firmware (bootcode.bin, start.elf, etc.)
3. Copies the bootloader kernel
4. Copies WiFi firmware
5. Creates template `wpa_supplicant.conf`
6. Creates partition ID files

## Step 4: Configure WiFi

Edit `wpa_supplicant.conf` on PXNK_A with your WiFi credentials:

**macOS:**
```bash
nano /Volumes/PXNK_A/wpa_supplicant.conf
```

**Linux:**
```bash
sudo nano /mnt/pxnk_a/wpa_supplicant.conf
```

Update with your credentials:
```
country=US

network={
    ssid="YourNetworkName"
    psk="YourPassword"
    proto=WPA2
    key_mgmt=WPA-PSK
}
```

**Important:**
- Use your 2-letter country code (US, GB, DE, etc.)
- SSID and password are case-sensitive
- Pi Zero 2 W only supports 2.4GHz WiFi (not 5GHz)

## Step 5: Eject and Test

**macOS:**
```bash
diskutil eject /dev/disk4
```

**Linux:**
```bash
sudo umount /mnt/pxnk_*
```

Then:
1. Insert SD card into Pi Zero 2 W
2. Connect serial console (optional but recommended for debugging)
3. Power on

## Expected Output

If everything is set up correctly, you should see on the serial console:

```
Pixelnuke Bootloader
Compile time: Jan 31 2025 19:31:00
Current partition: A
Waiting 2 seconds for serial upload...
Connecting to WiFi...
Network up: 192.168.1.xxx
TFTP: tftp -m binary 192.168.1.xxx -c put pxnk_pixelnuke_kernel.img
Starting TFTP server...
Waiting for firmware upload...
```

The bootloader is now ready to receive firmware updates via TFTP.

## Boot Partition Contents

Each boot partition (A and B) contains:

```
PXNK_A/
├── bootcode.bin          # GPU first-stage bootloader
├── start.elf             # GPU firmware
├── fixup.dat             # GPU memory configuration
├── bcm2710-rpi-zero-2-w.dtb  # Device tree
├── config.txt            # Pi configuration
├── cmdline.txt           # Kernel command line
├── kernel8.img           # Bootloader/Application
├── wpa_supplicant.conf   # WiFi credentials
├── .partition_id         # "A" or "B" identifier
├── bootcount             # Boot failure counter
└── firmware/             # WiFi firmware files
    ├── brcmfmac43430-sdio.bin
    ├── brcmfmac43430-sdio.txt
    └── brcmfmac43430-sdio.clm_blob
```

## Troubleshooting

### Partitions don't mount after formatting
- macOS: Try ejecting and reinserting the SD card
- Linux: Run `sudo partprobe /dev/sdX` then mount manually

### "Permission denied" during partitioning
- macOS: The script uses `diskutil` which may require admin privileges
- Linux: Run with `sudo`

### WiFi doesn't connect
1. Check `wpa_supplicant.conf` credentials (case-sensitive!)
2. Ensure country code matches your region
3. Verify you're using a 2.4GHz network
4. Check serial console for error messages

### Boot loop or no output
1. Verify `kernel8.img` was copied correctly (should be ~800KB)
2. Check `config.txt` exists and has `arm_64bit=1`
3. Try a different SD card
4. Check power supply (needs 5V 2.5A)

### "Could not detect partition, assuming A"
The `.partition_id` file is missing. Recreate it:
```bash
echo "A" > /Volumes/PXNK_A/.partition_id
echo "B" > /Volumes/PXNK_B/.partition_id
```

## Next Steps

- [Firmware Updates](firmware-updates.md) - Upload new firmware via Serial or TFTP
- [Debugging](debugging.md) - Serial console setup and troubleshooting
