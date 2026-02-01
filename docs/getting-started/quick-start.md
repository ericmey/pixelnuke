# Quick Start Guide

Get Pixelnuke running on your Pi Zero 2 W in 15 minutes.

## What You'll Need

### Hardware
- Raspberry Pi Zero 2 W
- microSD card (8GB+)
- USB-C power supply (5V 2.5A)
- USB-to-Serial adapter (for debugging, optional but recommended)
- Pimoroni Pirate Audio HAT (for audio output)

### Software
- macOS or Linux computer
- ARM cross-compiler (`aarch64-none-elf-gcc` or `aarch64-linux-gnu-gcc`)
- Git

## Step 1: Clone the Repository

```bash
git clone --recursive https://github.com/yourusername/pixelnuke.git
cd pixelnuke
```

## Step 2: Build the Bootloader

```bash
# Install ARM toolchain (if not already installed)
# macOS: brew install --cask gcc-arm-embedded
# Ubuntu: sudo apt install gcc-aarch64-linux-gnu

# Configure Circle framework
cd circle
./configure -r 3 -p aarch64-none-elf-   # or aarch64-linux-gnu-
cd ..

# Build Circle libraries (first time only)
make -C src/bootloader libs

# Build bootloader
make -C src/bootloader
```

## Step 3: Prepare SD Card

```bash
# Insert SD card and find device
diskutil list  # macOS
lsblk          # Linux

# Partition SD card (WARNING: erases all data)
./boot/partition-sd.sh /dev/diskN

# Set up A/B boot (after partitions mount)
./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B
```

## Step 4: Configure WiFi

Edit `wpa_supplicant.conf` on the PXNK_A partition:

```
country=US

network={
    ssid="YourNetworkName"
    psk="YourPassword"
    proto=WPA2
    key_mgmt=WPA-PSK
}
```

## Step 5: Boot

1. Safely eject SD card
2. Insert into Pi Zero 2 W
3. Power on
4. Connect serial console (optional): `screen /dev/tty.usbmodem* 115200`

You should see:
```
Pixelnuke Bootloader
Network up: 192.168.1.xxx
```

## Step 6: Update via Network

```bash
# Build new firmware
make -C src/bootloader

# Upload via TFTP
cp src/bootloader/kernel8.img pxnk_pixelnuke_kernel.img
tftp -m binary 192.168.1.xxx -c put pxnk_pixelnuke_kernel.img
```

## Next Steps

- [SD Card Setup](../bootloader/sd-card-setup.md) - Detailed SD card guide
- [Firmware Updates](../bootloader/firmware-updates.md) - Serial and WiFi updates
- [Hardware Setup](../hardware/setup.md) - Wiring and connections
- [Debugging](../bootloader/debugging.md) - Troubleshooting

## Troubleshooting

### Build fails with "command not found: aarch64..."
Install the ARM toolchain:
```bash
# macOS
brew install --cask gcc-arm-embedded

# Ubuntu/Debian
sudo apt install gcc-aarch64-linux-gnu
```

### No serial output
- Check TX/RX wiring (TX→RX, RX→TX)
- Verify baud rate: 115200
- Try a different USB port

### WiFi doesn't connect
- Double-check SSID and password (case-sensitive)
- Ensure 2.4GHz network (5GHz not supported)
- Check country code matches your region
