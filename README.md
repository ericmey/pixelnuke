# pixelnuke

A bare metal drum machine / sample player for Raspberry Pi Zero 2 W.

Built with the [Circle](https://github.com/rsta2/circle) bare metal framework.

## Hardware

- Raspberry Pi Zero 2 W
- Pimoroni Pirate Audio Line-Out HAT (PCM5100A DAC + ST7789 display)
- Seeed Xiao RP2040 (USB-to-serial for bootloader)

## Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/ericmey/pixelnuke.git
cd pixelnuke

# Download Pi boot firmware
cd circle/boot && make && cd ../..

# Build bootloader
cd circle/tools/bootloader && make && cd ../../..

# Prepare SD card (FAT32 formatted)
./boot/prepare-sd.sh /Volumes/BOOT

# Build the project
./configure
make

# Flash via serial
./flash.sh
```

## Development

See [docs/bare-metal-drum-machine-handoff.md](docs/bare-metal-drum-machine-handoff.md) for full project details.

## License

TBD
