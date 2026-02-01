#!/bin/bash
#
# Partition SD card for Pixelnuke A/B boot scheme (Linux)
#
# Layout:
#   Partition 1: 256MB  - Boot selector (autoboot.txt)
#   Partition 2: 1GB    - Boot A (kernel, firmware, factory content)
#   Partition 3: 1GB    - Boot B (identical to A)
#   Partition 4: Rest   - User data (samples, projects)
#
# Usage:
#   ./partition-sd.sh /dev/sdX
#
# WARNING: This will ERASE ALL DATA on the target disk!

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <disk>"
    echo ""
    echo "Example:"
    echo "  $0 /dev/sdb"
    echo ""
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL | tail -n +2
    exit 1
fi

DISK="$1"

# Safety check - don't allow partitioning the system disk
if [ "$DISK" == "/dev/sda" ]; then
    echo "ERROR: Refusing to partition /dev/sda (likely system disk)!"
    exit 1
fi

# Check if disk exists
if [ ! -b "$DISK" ]; then
    echo "ERROR: Disk $DISK does not exist or is not a block device"
    exit 1
fi

echo "========================================"
echo "Pixelnuke SD Card Partitioner (Linux)"
echo "========================================"
echo ""
echo "Target disk: $DISK"
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

# Unmount all partitions
for part in ${DISK}*; do
    sudo umount "$part" 2>/dev/null || true
done

# Create partitions using fdisk
# Partition type c = W95 FAT32 (LBA)
sudo fdisk "$DISK" << EOF
o
n
p
1

+256M
n
p
2

+1G
n
p
3

+1G
n
p
4


t
1
c
t
2
c
t
3
c
t
4
c
a
1
w
EOF

sleep 2

# Re-read partition table
sudo partprobe "$DISK"

sleep 1

# Format partitions
echo "Formatting partitions..."

sudo mkfs.vfat -F 32 -n PXNK_BOOT "${DISK}1"
sudo mkfs.vfat -F 32 -n PXNK_A "${DISK}2"
sudo mkfs.vfat -F 32 -n PXNK_B "${DISK}3"
sudo mkfs.vfat -F 32 -n PXNK_USER "${DISK}4"

echo ""
echo "========================================"
echo "Partitioning complete!"
echo "========================================"
echo ""
echo "Partitions created:"
lsblk "$DISK"
echo ""
echo "Next steps:"
echo "  1. Mount the partitions"
echo "  2. Run: ./boot/setup-ab-boot.sh <PXNK_BOOT> <PXNK_A> <PXNK_B>"
echo ""
