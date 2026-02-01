#!/bin/bash
#
# Partition SD card for Pixelnuke A/B boot scheme (macOS)
#
# Layout:
#   Partition 1: 256MB  - Boot selector (autoboot.txt)
#   Partition 2: 1GB    - Boot A (kernel, firmware, factory content)
#   Partition 3: 1GB    - Boot B (identical to A)
#   Partition 4: Rest   - User data (samples, projects)
#
# Usage:
#   ./partition-sd.sh /dev/diskN
#
# WARNING: This will ERASE ALL DATA on the target disk!

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <disk>"
    echo ""
    echo "Example:"
    echo "  $0 /dev/disk4"
    echo ""
    echo "Available disks:"
    diskutil list | grep -E "^/dev/disk"
    exit 1
fi

DISK="$1"

# Safety check - don't allow partitioning the system disk
if [ "$DISK" == "/dev/disk0" ] || [ "$DISK" == "/dev/disk1" ]; then
    echo "ERROR: Refusing to partition system disk!"
    exit 1
fi

# Check if disk exists
if ! diskutil info "$DISK" > /dev/null 2>&1; then
    echo "ERROR: Disk $DISK does not exist"
    exit 1
fi

# Get disk info for display
DISK_SIZE=$(diskutil info "$DISK" | grep "Disk Size" | awk '{print $3, $4}')
DISK_NAME=$(diskutil info "$DISK" | grep "Device / Media Name" | cut -d: -f2 | xargs)

echo "========================================"
echo "Pixelnuke SD Card Partitioner (macOS)"
echo "========================================"
echo ""
echo "Target disk: $DISK"
echo "Disk size:   $DISK_SIZE"
echo "Disk name:   $DISK_NAME"
echo ""
echo "This will create:"
echo "  Partition 1: 256MB  - PXNK_BOOT (boot selector)"
echo "  Partition 2: 1GB    - PXNK_A (Boot A)"
echo "  Partition 3: 1GB    - PXNK_B (Boot B)"
echo "  Partition 4: Rest   - PXNK_USER (User data)"
echo ""
echo "WARNING: ALL DATA ON $DISK WILL BE ERASED!"
echo ""
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Partitioning $DISK..."

# Unmount all volumes
diskutil unmountDisk "$DISK" 2>/dev/null || true

# Partition with MBR scheme and FAT32 filesystems
# R = remaining space for last partition
diskutil partitionDisk "$DISK" MBR \
    FAT32 PXNK_BOOT 256MB \
    FAT32 PXNK_A 1GB \
    FAT32 PXNK_B 1GB \
    FAT32 PXNK_USER R

echo ""
echo "========================================"
echo "Partitioning complete!"
echo "========================================"
echo ""
echo "Partitions created:"
diskutil list "$DISK"
echo ""
echo "Next steps:"
echo "  Run: ./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B"
echo ""
