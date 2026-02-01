# Pin Reference

GPIO assignments for Pixelnuke on Pi Zero 2 W.

## Header Pinout

```
                    Pi Zero 2 W Header
                    ┌─────────────────┐
              3.3V  │ 1           2   │  5V
   (I2C SDA) GPIO2  │ 3           4   │  5V
   (I2C SCL) GPIO3  │ 5           6   │  GND
             GPIO4  │ 7           8   │  GPIO14 (UART TX)
               GND  │ 9          10   │  GPIO15 (UART RX)
            GPIO17  │ 11         12   │  GPIO18 (I2S BCK)
            GPIO27  │ 13         14   │  GND
            GPIO22  │ 15         16   │  GPIO23
              3.3V  │ 17         18   │  GPIO24 (SWD DIO)
  (SPI MOSI) GPIO10 │ 19         20   │  GND
  (SPI MISO) GPIO9  │ 21         22   │  GPIO25 (SWD CLK)
  (SPI SCLK) GPIO11 │ 23         24   │  GPIO8  (SPI CE0)
               GND  │ 25         26   │  GPIO7  (SPI CE1)
            GPIO0   │ 27         28   │  GPIO1
            GPIO5   │ 29         30   │  GND
            GPIO6   │ 31         32   │  GPIO12
            GPIO13  │ 33         34   │  GND
 (I2S LRCK) GPIO19  │ 35         36   │  GPIO16
            GPIO26  │ 37         38   │  GPIO20
               GND  │ 39         40   │  GPIO21 (I2S DOUT)
                    └─────────────────┘
```

## Function Assignments

### UART (Serial Console)
| GPIO | Pin | Function |
|------|-----|----------|
| 14 | 8 | UART TX |
| 15 | 10 | UART RX |

### I2S Audio (PCM5100A DAC)
| GPIO | Pin | Function |
|------|-----|----------|
| 18 | 12 | I2S BCK (Bit Clock) |
| 19 | 35 | I2S LRCK (Word Clock) |
| 21 | 40 | I2S DOUT (Data Out) |

### SPI (ST7789 Display)
| GPIO | Pin | Function |
|------|-----|----------|
| 10 | 19 | SPI MOSI |
| 11 | 23 | SPI SCLK |
| 8 | 24 | SPI CE0 (Chip Select) |
| 9 | 21 | SPI MISO (not used by display) |

### Display Control
| GPIO | Pin | Function |
|------|-----|----------|
| 25 | 22 | DC (Data/Command) |
| 27 | 13 | Backlight |

### Buttons (Pirate Audio)
| GPIO | Pin | Function |
|------|-----|----------|
| 5 | 29 | Button A |
| 6 | 31 | Button B |
| 16 | 36 | Button X |
| 24 | 18 | Button Y |

### SWD Debug
| GPIO | Pin | Function |
|------|-----|----------|
| 24 | 18 | SWDIO |
| 25 | 22 | SWCLK |

**Note:** GPIO24 and GPIO25 are shared between buttons and SWD. SWD debugging requires disconnecting Button Y and display DC.

## Config.txt Settings

```ini
# UART for serial console
enable_uart=1
core_freq=250

# I2S audio
dtparam=i2s=on
dtoverlay=hifiberry-dac

# SPI for display
dtparam=spi=on

# Disable unused interfaces
dtparam=i2c_arm=off
dtparam=audio=off

# 64-bit mode
arm_64bit=1
```
