# Display Setup

Pixelnuke uses an ST7789 240x240 LCD for visual feedback.

## Supported Hardware

### Pimoroni Pirate Audio (Integrated)
The Pirate Audio HAT includes an ST7789 display that connects automatically.

### Standalone ST7789 Module
Generic ST7789 modules (240x240 or 240x320) can be used with appropriate wiring.

## SPI Wiring

```
ST7789 Display         Pi Zero 2 W
──────────────         ────────────
VCC           ─        3.3V
GND           ─        GND
SCL/SCLK      ←        GPIO11 (pin 23) - SPI Clock
SDA/MOSI      ←        GPIO10 (pin 19) - SPI Data
DC            ←        GPIO25 (pin 22) - Data/Command
CS            ←        GPIO8  (pin 24) - Chip Select
BL            ←        GPIO27 (pin 13) - Backlight
RST           ←        (optional, can tie to 3.3V)
```

## Configuration

### config.txt
```ini
# Enable SPI
dtparam=spi=on
```

## Display Specifications

| Parameter | Value |
|-----------|-------|
| Resolution | 240 × 240 pixels |
| Color Depth | 16-bit (RGB565) |
| Interface | SPI |
| SPI Speed | Up to 62.5 MHz |

## Usage

The display is managed by Circle's ST7789 driver. In application code:

```cpp
#include <circle/screen.h>

// Initialize
CScreenDevice Screen(240, 240);
Screen.Initialize();

// Draw pixel
Screen.SetPixel(x, y, COLOR16(r, g, b));

// Clear screen
Screen.Clear(COLOR16(0, 0, 0));
```

## Troubleshooting

### Blank screen
1. Check VCC and GND connections
2. Verify SPI wiring (SCL, SDA, CS)
3. Check DC pin connection
4. Try enabling backlight manually

### Wrong colors
1. Check RGB order configuration
2. Verify color format (RGB565)

### Flickering
1. Check SPI clock speed (try reducing)
2. Verify stable power supply
3. Check for loose connections

## Technical Notes

The ST7789 driver in Circle handles:
- SPI communication
- Display initialization sequence
- Framebuffer management
- Hardware acceleration (where available)

Display updates are typically done in a dedicated core to avoid affecting audio timing.
