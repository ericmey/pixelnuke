# Audio Setup

Pixelnuke uses I2S audio output through a PCM5100A DAC.

## Supported Hardware

### Pimoroni Pirate Audio Line-Out (Recommended)
- PCM5100A DAC with line-out jack
- Integrated ST7789 240x240 LCD
- 4 GPIO buttons
- Mounts directly on Pi header

### Generic PCM5100A DAC
Any PCM5100A-based I2S DAC board should work with correct wiring.

## I2S Wiring

```
PCM5100A               Pi Zero 2 W
────────               ────────────
BCK/BCLK      ←        GPIO18 (pin 12) - Bit Clock
LRCK/WCLK     ←        GPIO19 (pin 35) - Word Clock
DIN/DATA      ←        GPIO21 (pin 40) - Data
GND           ─        GND
VIN           ─        3.3V or 5V (check DAC specs)
```

## Configuration

### config.txt
```ini
# Enable I2S
dtparam=i2s=on

# Use HiFiBerry DAC overlay (works for PCM5100A)
dtoverlay=hifiberry-dac

# Disable onboard audio (not used)
dtparam=audio=off
```

### cmdline.txt
```
sounddev=sndi2s
```

## Audio Specifications

| Parameter | Value |
|-----------|-------|
| Sample Rate | 44.1 kHz (configurable) |
| Bit Depth | 16-bit |
| Channels | Stereo |
| Output Level | Line level (~1V RMS) |
| THD+N | <0.001% (PCM5100A spec) |

## Troubleshooting

### No audio output
1. Check I2S wiring (BCK, LRCK, DIN)
2. Verify `dtoverlay=hifiberry-dac` in config.txt
3. Check DAC power supply

### Distorted audio
1. Check sample rate matches source
2. Verify clean power supply
3. Check for ground loops

### Audio glitches/dropouts
1. CPU may be throttling - check temperature
2. DMA buffer underruns - check system load
3. WiFi interference - some DAC boards are sensitive

## Technical Notes

The I2S interface runs at:
- BCLK = Sample Rate × Bits × Channels = 44100 × 16 × 2 = 1.4112 MHz
- LRCK = Sample Rate = 44.1 kHz

Circle's I2S driver handles timing and DMA automatically.
