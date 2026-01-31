# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pixelnuke is a bare metal drum machine / sample player for Raspberry Pi Zero 2 W using the Circle framework. It loads drum samples from SD card, triggers via MIDI/buttons, and outputs audio through an I2S DAC (PCM5100A on Pimoroni Pirate Audio HAT).

**Status**: Early infrastructure phase - no application code yet.

## Hardware Target

- **Pi Zero 2 W**: BCM2710A1 (quad-core Cortex-A53), uses `RASPPI=3` for Circle builds
- **Audio HAT**: Pimoroni Pirate Audio Line-Out (PCM5100A DAC, ST7789 240x240 LCD, 4 GPIO buttons)
- **Serial Debug**: Seeed Xiao RP2040 as USB-to-Serial bridge

## Build Commands

```bash
# Configure Circle (from circle/ directory)
./configure 3 arm-none-eabi-        # 32-bit build
./configure 3 arm-none-eabi- 64     # 64-bit build

# Build all components
./makeall

# Clean build
./makeall clean

# Flash kernel via serial bootloader (fast iteration)
./flash.sh

# Prepare SD card with boot files
./boot/prepare-sd.sh /Volumes/BOOT
```

## Architecture

### Multi-Core Layout (Planned)
- **Core 0**: Sequencer logic, pattern playback, UI state machine
- **Core 1**: Audio engine - sample mixing, DMA buffer filling
- **Core 2**: Display updates - ST7789 rendering
- **Core 3**: Network - HTTP server for web interface

### Key Components to Build
- `CSampleVoice`: Individual sample player with velocity control
- `CDrumKit`: 16-voice mixer for drum samples
- `CSequencer`: Pattern playback engine
- `CUI`: ST7789 display interface
- `CMIDI`: USB MIDI input handler

## Circle Framework

Circle (v50.0.1) is included as a git submodule. It provides:
- I2S audio driver, ST7789 display driver, GPIO, FatFs filesystem, USB MIDI, WiFi
- No Linux kernel - pure bare metal with multi-core support

Key references:
- `circle/sample/` - Example programs (start with sound samples)
- `circle/lib/` - Core library headers
- Circle docs: https://circle-rpi.readthedocs.io

## Development Notes

- QEMU does NOT emulate I2S, SPI, DMA, or WiFi - real hardware required
- Serial bootloader enables ~2-3 second kernel uploads vs SD card swapping
- Tab size is 8 spaces (embedded convention)
- Output: `kernel8-32.img` (32-bit) or `kernel8.img` (64-bit)

## Key Documentation

- `docs/bare-metal-drum-machine-handoff.md` - Comprehensive project handoff (hardware pinouts, architecture, roadmap)
- `README.md` - Quick start and hardware inventory
