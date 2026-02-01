# Bootloader Architecture

This document provides a technical deep-dive into the Pixelnuke bootloader architecture.

## Overview

The bootloader is a bare-metal application built on the Circle framework. It runs directly on the ARM Cortex-A53 cores without an operating system.

## Source Structure

```
src/bootloader/
├── main.cpp              # Entry point, calls kernel
├── kernel.cpp            # Main bootloader logic
├── kernel.h              # Kernel class definition
├── tftpbootserver.cpp    # TFTP daemon implementation
├── tftpbootserver.h      # TFTP class definition
├── Makefile              # Build configuration
└── .cppcheck-suppressions  # Static analysis config
```

## Class Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        CKernel                               │
├─────────────────────────────────────────────────────────────┤
│ - m_Screen: CScreenDevice                                    │
│ - m_Serial: CSerialDevice                                    │
│ - m_Timer: CTimer                                            │
│ - m_USBHCI: CUSBHCIDevice                                    │
│ - m_EMMC: CEMMCDevice                                        │
│ - m_FileSystem: FATFS                                        │
│ - m_WLAN: CBcm4343Device                                     │
│ - m_Net: CNetSubSystem                                       │
│ - m_WPASupplicant: CWPASupplicant                            │
├─────────────────────────────────────────────────────────────┤
│ + Initialize(): boolean                                      │
│ + Run(): TShutdownMode                                       │
│ - DetectCurrentPartition(): char                             │
│ - SetTrybootFlag(bEnable): boolean                           │
│ - WaitForSerialUpload(): boolean                             │
│ + static RequestReboot(partition): void                      │
│ + static GetCurrentPartition(): char                         │
│ + static GetAlternatePartition(): char                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ creates
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CTFTPBootServer                           │
│                  (extends CTFTPDaemon)                       │
├─────────────────────────────────────────────────────────────┤
│ - m_nMaxKernelSize: size_t                                   │
│ - m_bFileOpen: boolean                                       │
│ - m_pKernelBuffer: u8*                                       │
│ - m_nCurrentOffset: unsigned                                 │
├─────────────────────────────────────────────────────────────┤
│ + FileOpen(fileName): boolean                                │
│ + FileCreate(fileName): boolean                              │
│ + FileClose(): boolean                                       │
│ + FileRead(buffer, count): int                               │
│ + FileWrite(buffer, count): int                              │
└─────────────────────────────────────────────────────────────┘
```

## Initialization Sequence

```cpp
// main.cpp
int main(void)
{
    CKernel Kernel;
    if (!Kernel.Initialize())
        return EXIT_HALT;

    TShutdownMode ShutdownMode = Kernel.Run();

    switch (ShutdownMode)
    {
        case ShutdownReboot:
            return EXIT_REBOOT;
        default:
            return EXIT_HALT;
    }
}
```

### CKernel::Initialize()

1. **Screen** - Framebuffer for debug output
2. **Serial** - UART at 115200 baud
3. **Logger** - Circle logging system
4. **Interrupt** - ARM interrupt controller
5. **Timer** - System timer
6. **USB** - USB host controller
7. **EMMC** - SD card controller
8. **FileSystem** - FatFs mount
9. **Partition Detection** - Read `.partition_id`
10. **WiFi Config Check** - Look for `wpa_supplicant.conf`
11. **WLAN** - Initialize WiFi hardware (if config exists)

## Main Loop

```cpp
TShutdownMode CKernel::Run(void)
{
    // 1. Serial bootloader window
    SendSerialReady();              // Send "IHEX-F\r\n"
    if (WaitForSerialUpload())      // Wait 2 seconds
        return ShutdownReboot;

    // 2. WiFi connection (if configured)
    if (m_bHaveWiFiConfig)
    {
        m_Net.Initialize(FALSE);
        m_WPASupplicant.Initialize();
        // Wait up to 30 seconds for connection
    }

    // 3. Start TFTP server
    if (m_bNetworkUp)
        new CTFTPBootServer(&m_Net, KERNEL_MAX_SIZE);

    // 4. Wait for upload
    while (!IsRebootRequested())
    {
        m_Screen.Rotor(0, nCount++);
        m_Scheduler.Yield();
    }

    // 5. Handle reboot to new partition
    if (cTarget != m_cCurrentPartition)
        SetTrybootFlag(TRUE);

    return ShutdownReboot;
}
```

## A/B Partition System

### Partition Structure

| Partition | Mount Point | Purpose |
|-----------|-------------|---------|
| 1 | PXNK_BOOT | Boot selector (autoboot.txt) |
| 2 | PXNK_A | Boot A (default) |
| 3 | PXNK_B | Boot B (updates) |
| 4 | PXNK_USER | User data |

### autoboot.txt

```ini
[all]
tryboot_a_b=1
boot_partition=2      # Default: partition A

[tryboot]
boot_partition=3      # Tryboot: partition B
```

### Tryboot Mechanism

The Raspberry Pi GPU firmware supports "tryboot" for A/B updates:

1. **Normal boot**: GPU reads `boot_partition=2`, boots from A
2. **After update**: Bootloader sets tryboot flag via mailbox
3. **Next boot**: GPU sees tryboot, reads `[tryboot]` section, boots from B
4. **If B fails**: Tryboot flag clears, next boot returns to A

### Mailbox Property

```cpp
boolean CKernel::SetTrybootFlag(boolean bEnable)
{
    CBcmPropertyTags Tags;

    struct TTrybootTag
    {
        TPropertyTag Tag;
        u32 nValue;
    } PACKED;

    TTrybootTag TrybootTag;
    TrybootTag.Tag.nTagId = PROPTAG_SET_REBOOT_FLAGS;  // 0x00038064
    TrybootTag.nValue = bEnable ? 1 : 0;

    return Tags.GetTag(PROPTAG_SET_REBOOT_FLAGS,
                       &TrybootTag, sizeof(TrybootTag),
                       sizeof(TrybootTag.nValue));
}
```

## TFTP Server

### Authentication

Files must start with `pxnk_pixelnuke_` prefix:

```cpp
#define TFTP_AUTH_PREFIX "pxnk_pixelnuke_"

boolean CTFTPBootServer::FileCreate(const char *pFileName)
{
    if (strncmp(pFileName, TFTP_AUTH_PREFIX, strlen(TFTP_AUTH_PREFIX)) != 0)
    {
        CLogger::Get()->Write(FromBootServer, LogWarning,
                              "Rejected file: %s (invalid prefix)", pFileName);
        return FALSE;
    }
    // ... continue with accepted file
}
```

### Upload Flow

```
Client                          Server
──────                          ──────
WRQ (pxnk_pixelnuke_kernel.img) ───►
                                ◄─── ACK 0
DATA block 1 (512 bytes)        ───►
                                ◄─── ACK 1
DATA block 2 (512 bytes)        ───►
                                ◄─── ACK 2
...
DATA block N (<512 bytes)       ───►
                                ◄─── ACK N
                                     │
                                     ▼
                              FileClose()
                              RequestReboot()
```

## Memory Layout

```
0x00000000 ┌─────────────────────┐
           │    Exception        │
           │    Vectors          │
0x00000800 ├─────────────────────┤
           │    Kernel Code      │
           │    (.text)          │
           ├─────────────────────┤
           │    Read-only Data   │
           │    (.rodata)        │
           ├─────────────────────┤
           │    Initialized      │
           │    Data (.data)     │
           ├─────────────────────┤
           │    BSS              │
           │    (zero-init)      │
           ├─────────────────────┤
           │    Heap             │
           │    (grows up)       │
           │         ↓           │
           │                     │
           │         ↑           │
           │    Stack            │
           │    (grows down)     │
0x3F000000 ├─────────────────────┤
           │    Peripherals      │
           │    (MMIO)           │
0x40000000 └─────────────────────┘
```

## Build System

### Makefile Targets

| Target | Description |
|--------|-------------|
| `make` | Build kernel8.img |
| `make clean` | Remove build artifacts |
| `make libs` | Build Circle libraries |
| `make format` | Format source with clang-format |
| `make lint` | Run cppcheck static analysis |
| `make check` | Run all quality checks |

### Compiler Flags

- `-mcpu=cortex-a53` - Target CPU
- `-mabi=lp64` - 64-bit ABI
- `-ffreestanding` - No standard library assumptions
- `-nostdlib` - Don't link standard library

## Dependencies

### Circle Modules Used

| Module | Purpose |
|--------|---------|
| libcircle | Core kernel functionality |
| libusb | USB host controller |
| libnet | TCP/IP networking |
| libsched | Cooperative scheduler |
| libfs | Filesystem abstraction |
| libwlan | WiFi driver |
| libfatfs | FAT filesystem |
| libsdcard | SD card driver |

### Build Order

Libraries must be linked in dependency order:
```makefile
LIBS = wpa_supplicant → wlan → fatfs → sdcard → net → sched → usb → input → fs → circle
```

## Future Enhancements

### Planned
- Firmware signature verification
- Rollback counter persistence
- HTTP server (moved to application layer)

### Considered
- Secure boot chain
- Encrypted firmware images
- Remote attestation
