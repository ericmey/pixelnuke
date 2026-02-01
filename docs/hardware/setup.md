# Hardware Setup

This guide covers the hardware setup for Pixelnuke.

## Components

### Required
- **Raspberry Pi Zero 2 W** - Main processor
- **microSD Card** - 8GB minimum, Class 10 recommended
- **USB-C Power Supply** - 5V 2.5A minimum

### Audio Output (Choose One)
- **Pimoroni Pirate Audio Line-Out** - PCM5100A DAC, ST7789 display, 4 buttons
- **Generic I2S DAC** - Any PCM5100A-based board

### Development/Debug
- **USB-to-Serial Adapter** - For serial console and fast uploads
  - Raspberry Pi Debug Probe (recommended)
  - FT232R, CH340, CP2102, etc.

## Wiring

### Serial Console / Bootloader

```
USB-Serial Adapter      Pi Zero 2 W
──────────────────      ────────────
TX          →           GPIO15 (pin 10)
RX          ←           GPIO14 (pin 8)
GND         ─           GND (pin 6)
```

### SWD Debug (Optional)

```
Debug Probe            Pi Zero 2 W
────────────           ────────────
SWCLK       →          GPIO25 (pin 22)
SWDIO       ↔          GPIO24 (pin 18)
GND         ─          GND
```

### I2S Audio (PCM5100A)

```
PCM5100A DAC           Pi Zero 2 W
────────────           ────────────
BCK         ←          GPIO18 (pin 12)
LRCK        ←          GPIO19 (pin 35)
DIN         ←          GPIO21 (pin 40)
GND         ─          GND
VIN         ─          3.3V or 5V (check DAC specs)
```

## Pin Reference

See [Pin Reference](pins.md) for complete GPIO assignments.

## Power Considerations

- Pi Zero 2 W draws ~200mA idle, up to 500mA under load
- Add headroom for WiFi and USB peripherals
- Use quality USB-C cable (data cables often have thin power wires)
- Avoid USB hubs for power (insufficient current)

## Heat Management

The BCM2710A1 can throttle under sustained load. For audio applications:
- Adequate ventilation recommended
- Small heatsink optional but helpful
- Avoid enclosures without ventilation

## Next Steps

- [Pin Reference](pins.md)
- [Audio Setup](audio.md)
- [Display Setup](display.md)
