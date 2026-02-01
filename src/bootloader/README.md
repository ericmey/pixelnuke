# Pixelnuke Bootloader

Minimal bootloader for Raspberry Pi Zero 2 W with Serial + TFTP firmware updates and A/B partition support.

## Features

- **Serial bootloader**: IHEX-F protocol for fast development uploads (~2-3 seconds)
- **TFTP server**: WiFi-based OTA updates on port 69
- **A/B partitions**: Safe firmware updates with automatic rollback
- **Tryboot support**: Uses Raspberry Pi GPU firmware's native A/B boot mechanism

## Build

```bash
# Build Circle libraries (first time only)
make libs

# Build bootloader
make

# Run code quality checks
make check
```

## Code Quality

This project uses automated code quality tools:

- **clang-format**: Code formatting (8-space tabs, Circle conventions)
- **cppcheck**: Static analysis

```bash
make format       # Format all source files
make format-check # Check formatting without modifying
make lint         # Run static analysis
make check        # Run all checks
```

## Partition Layout

```
Partition 1: PXNK_BOOT (256MB) - Boot selector with autoboot.txt
Partition 2: PXNK_A    (1GB)   - Boot A (default)
Partition 3: PXNK_B    (1GB)   - Boot B (updates)
Partition 4: PXNK_USER (rest)  - User data
```

## OTA Update Flow

1. Bootloader receives firmware via Serial or TFTP
2. Writes to alternate partition (A→B or B→A)
3. Sets tryboot flag via GPU mailbox
4. Reboots to new partition
5. If successful, new partition becomes default

## TFTP Upload

Files must be prefixed with authentication token:

```bash
tftp -m binary <pi-ip> -c put pxnk_pixelnuke_kernel.img
```

## Files

- `kernel.cpp/h` - Main bootloader with A/B partition management
- `tftpbootserver.cpp/h` - TFTP daemon for firmware uploads
- `main.cpp` - Entry point

## Configuration

- `.clang-format` - Code style configuration
- `.cppcheck-suppressions` - Static analysis suppressions
