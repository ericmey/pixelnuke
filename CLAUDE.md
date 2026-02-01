# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

Pixelnuke is a bare metal drum machine / sample player for Raspberry Pi Zero 2 W using the Circle framework. It loads drum samples from SD card, triggers via MIDI/buttons, and outputs audio through an I2S DAC (PCM5100A on Pimoroni Pirate Audio HAT).

**Status**: Infrastructure phase - bootloader complete, main application in development.

## Hardware Target

- **Pi Zero 2 W**: BCM2710A1 (quad-core Cortex-A53), uses `RASPPI=3` for Circle builds
- **WiFi**: BCM43430 (uses `brcmfmac43430-sdio.*` firmware, NOT 43436)
- **Audio HAT**: Pimoroni Pirate Audio Line-Out (PCM5100A DAC, ST7789 240x240 LCD, 4 buttons)
- **Debug Probe**: Raspberry Pi Debug Probe (SWD + UART)

## Project Structure

```
pixelnuke/
├── src/
│   ├── bootloader/           # Serial + TFTP firmware update system
│   │   ├── kernel.cpp/h      # Main bootloader with A/B partition support
│   │   ├── tftpbootserver.cpp/h  # TFTP upload server
│   │   ├── main.cpp          # Entry point
│   │   └── Makefile          # Build with format/lint/check targets
│   └── app/                  # Main drum machine (TODO)
├── circle/                   # Circle framework (submodule)
├── docs/                     # USER DOCUMENTATION (public-facing)
│   ├── bootloader/           # Bootloader guides
│   ├── getting-started/      # Quick start guides
│   ├── hardware/             # Wiring and setup
│   └── api/                  # API reference
├── dev/                      # INTERNAL development resources
│   ├── research/             # Competitor research
│   └── bare-metal-drum-machine-handoff.md
├── boot/                     # SD card setup scripts
│   ├── partition-sd.sh       # Create A/B partition layout
│   └── setup-ab-boot.sh      # Populate boot partitions
├── openocd/                  # Debug configurations
├── .github/workflows/        # CI pipeline
├── .clang-format             # Code style (project-wide)
├── .editorconfig             # Editor settings
└── flash.sh                  # Serial flash utility
```

## Build Commands

```bash
# First-time setup
cd circle && ./configure -r 3 -p aarch64-none-elf-
cd ..
make -C src/bootloader libs   # Build Circle libraries

# Build bootloader
make -C src/bootloader

# Run all checks (format + lint)
make -C src/bootloader check

# Flash via serial
./flash.sh

# Prepare SD card (A/B partitions)
./boot/partition-sd.sh /dev/diskN
./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B
```

## Bootloader Architecture

### A/B Partition Scheme
```
Partition 1: PXNK_BOOT (256MB) - Boot selector with autoboot.txt
Partition 2: PXNK_A    (1GB)   - Boot A (default)
Partition 3: PXNK_B    (1GB)   - Boot B (updates)
Partition 4: PXNK_USER (rest)  - User data
```

### Update Methods
1. **Serial** (development): 2-second window at boot for IHEX-F protocol upload
2. **TFTP** (WiFi OTA): `tftp -m binary <ip> -c put pxnk_pixelnuke_kernel.img`

### Boot Flow
1. GPU reads autoboot.txt, selects partition A or B
2. Bootloader sends "IHEX-F\r\n", waits 2s for serial upload
3. Connects to WiFi (if wpa_supplicant.conf exists)
4. Starts TFTP server on port 69
5. On upload: writes to alternate partition, sets tryboot flag, reboots
6. On boot failure: automatic rollback via tryboot mechanism

---

## Development Rules

### Documentation Requirements

**When completing any component:**
1. Update relevant docs in `/docs/` (user-facing documentation)
2. Keep `/dev/` for internal notes only
3. Documentation must include:
   - Overview/purpose
   - Setup/installation steps
   - Usage examples
   - Troubleshooting section

**Documentation locations:**
- `/docs/` = User and developer documentation (public-facing, kept up to date)
- `/dev/` = Internal development resources (research, planning, may be outdated)
- `/src/*/README.md` = Component-specific technical docs
- `CLAUDE.md` = AI assistant guidance (this file)

### Testing Requirements

**Before any commit:**
1. Run `make -C src/bootloader check` (format + lint must pass)
2. Run `make -C src/bootloader` (build must succeed)
3. If hardware-affecting changes: test on real Pi Zero 2 W

**Before any push:**
1. All commits must pass CI checks
2. Documentation must be updated for any user-facing changes
3. Test on hardware if:
   - Boot flow changed
   - Network code changed
   - Partition handling changed
   - Any low-level driver changes

### Validation Checklist

**For bootloader changes:**
- [ ] `make check` passes
- [ ] Build produces valid kernel8.img
- [ ] Serial console shows expected output
- [ ] WiFi connects (if wpa_supplicant.conf exists)
- [ ] TFTP upload works with correct prefix
- [ ] A/B partition switching works
- [ ] Tryboot fallback works on failure

**For new components:**
- [ ] Code follows 8-space tab convention
- [ ] Functions have clear purpose
- [ ] No unnecessary complexity
- [ ] Documentation added to `/docs/`
- [ ] README.md in component directory
- [ ] Build targets added to Makefile

### Code Quality Standards

**Style:**
- 8-space tabs (enforced by .clang-format)
- Max 100 character lines
- Circle framework naming conventions (CClassName, m_MemberVar)

**Tools:**
- `make format` - Auto-format code
- `make lint` - Static analysis (cppcheck)
- `make check` - Run all checks

**Suppressions:**
- Circle framework warnings: suppressed (we don't control that code)
- Intentional patterns: document in .cppcheck-suppressions with reason

### Commit Workflow

1. Make changes
2. Run `make -C src/bootloader check`
3. Fix any issues
4. Test on hardware (if applicable)
5. Update documentation (if user-facing changes)
6. Commit with descriptive message
7. Push only after all checks pass

---

## Circle Framework Notes

- Circle v50.0.1 as git submodule
- Single-core build for bootloader (chain boot requires this)
- Multi-core build for application
- No QEMU testing - I2S, SPI, DMA, WiFi require real hardware

## SWD Debugging

```bash
# Wiring: SWCLK→GPIO25, SWDIO→GPIO24, GND→GND

# Start OpenOCD
openocd -f openocd/rpi-debug-probe.cfg

# Connect GDB
aarch64-none-elf-gdb -ex "target extended-remote :3333" src/bootloader/kernel8.elf
```

## Key Documentation

- `/docs/` - Complete user documentation
- `/docs/bootloader/` - Bootloader setup and usage
- `/dev/bare-metal-drum-machine-handoff.md` - Original project planning
