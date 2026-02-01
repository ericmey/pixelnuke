# Pixelnuke

A bare metal drum machine / sample player for Raspberry Pi Zero 2 W.

Built with the [Circle](https://github.com/rsta2/circle) bare metal framework.

## Features

- **Bare Metal**: No Linux, direct hardware access for low-latency audio
- **OTA Updates**: WiFi-based firmware updates via TFTP
- **A/B Partitions**: Safe updates with automatic rollback
- **Fast Development**: Serial bootloader for 2-3 second upload cycles

## Hardware

- Raspberry Pi Zero 2 W
- Pimoroni Pirate Audio Line-Out HAT (PCM5100A DAC + ST7789 display)
- USB-to-Serial adapter (Raspberry Pi Debug Probe recommended)

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/yourusername/pixelnuke.git
cd pixelnuke

# Configure Circle (first time)
cd circle && ./configure -r 3 -p aarch64-none-elf-
cd ..

# Build
make -C src/bootloader libs   # First time only
make -C src/bootloader

# Prepare SD card
./boot/partition-sd.sh /dev/diskN
./boot/setup-ab-boot.sh /Volumes/PXNK_BOOT /Volumes/PXNK_A /Volumes/PXNK_B

# Flash via serial
./flash.sh
```

## Documentation

- [Quick Start Guide](docs/getting-started/quick-start.md)
- [Bootloader Overview](docs/bootloader/overview.md)
- [SD Card Setup](docs/bootloader/sd-card-setup.md)
- [Firmware Updates](docs/bootloader/firmware-updates.md)
- [Hardware Setup](docs/hardware/setup.md)

## Project Status

| Component | Status |
|-----------|--------|
| Bootloader | ✅ Complete |
| Serial Upload | ✅ Complete |
| WiFi OTA (TFTP) | ✅ Complete |
| A/B Partitions | ✅ Complete |
| Audio Engine | 🚧 Planned |
| Sequencer | 🚧 Planned |
| Web Interface | 🚧 Planned |

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

For AI-assisted development, see [CLAUDE.md](CLAUDE.md).

## License

TBD
