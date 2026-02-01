# Windows Tools

Windows-specific tools for Pixelnuke development.

## Planned

- `partition-sd.ps1` - PowerShell script for SD card partitioning

## Current Status

Not yet implemented. For now, use a Linux VM or WSL, or manually partition using Disk Management.

### Manual Partitioning with Disk Management

1. Open Disk Management (Win+X → Disk Management)
2. Right-click the SD card → Delete all partitions
3. Create 4 partitions:
   - 256MB FAT32 - Label: PXNK_BOOT
   - 1GB FAT32 - Label: PXNK_A
   - 1GB FAT32 - Label: PXNK_B
   - Remaining FAT32 - Label: PXNK_USER
4. Mark the first partition as active

Note: Windows Disk Management may not allow creating 4 primary partitions on MBR. Consider using diskpart or a third-party tool like Rufus.
