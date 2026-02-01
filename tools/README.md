# Tools

OS-specific tools and utilities for Pixelnuke development.

## Directory Structure

```
tools/
├── macos/              # macOS-specific tools
│   └── partition-sd.sh # SD card partitioner using diskutil
├── linux/              # Linux-specific tools
│   └── partition-sd.sh # SD card partitioner using fdisk
├── windows/            # Windows-specific tools (planned)
│   └── README.md       # Manual instructions for now
└── debugprobe_xiao_rp2040.uf2  # Debug probe firmware
```

## SD Card Partitioning

### macOS
```bash
./tools/macos/partition-sd.sh /dev/diskN
```

### Linux
```bash
./tools/linux/partition-sd.sh /dev/sdX
```

### Windows
See `windows/README.md` for manual instructions.

## After Partitioning

Run the setup script to populate the boot partitions:

```bash
# macOS
./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B

# Linux (adjust mount points as needed)
./boot/setup-ab-boot.sh /mnt/pxnk_boot /mnt/pxnk_a /mnt/pxnk_b
```

## Debug Probe Firmware

`debugprobe_xiao_rp2040.uf2` - Firmware for using Seeed XIAO RP2040 as a debug probe.

To flash:
1. Hold BOOT button while connecting USB
2. Drag and drop the .uf2 file to the RPI-RP2 drive
