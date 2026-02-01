# Pixelnuke Documentation

Pixelnuke is a bare metal drum machine / sample player for Raspberry Pi Zero 2 W.

## Documentation

### Getting Started
- [Quick Start Guide](getting-started/quick-start.md) - Get up and running
- [Hardware Setup](hardware/setup.md) - Wiring and components

### Bootloader
- [Overview](bootloader/overview.md) - How the bootloader works
- [SD Card Setup](bootloader/sd-card-setup.md) - Partition layout and preparation
- [Firmware Updates](bootloader/firmware-updates.md) - Serial and WiFi OTA updates
- [Debugging](bootloader/debugging.md) - Troubleshooting and serial console
- [Architecture](bootloader/architecture.md) - Technical deep-dive

### Hardware
- [Pin Reference](hardware/pins.md) - GPIO assignments
- [Audio Setup](hardware/audio.md) - I2S DAC configuration
- [Display](hardware/display.md) - ST7789 LCD setup

### API Reference
- [Coming Soon](api/README.md)

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

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for development guidelines.
