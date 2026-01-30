# Bare Metal Drum Machine Project - Comprehensive Handoff

## Project Overview

I'm building a **bare metal drum machine/sample player** on a Raspberry Pi Zero 2 W using the **Circle framework**. The goal is to create a practice backing track player that loads drum samples from SD card and outputs through an I2S DAC. This is intentionally a challenging project for learning embedded systems, DMA, interrupts, and real-time audio programming.

---

## Hardware Inventory

### Main Unit
- **Raspberry Pi Zero 2 W**
  - SoC: BCM2710A1 (quad-core Cortex-A53 @ 1GHz)
  - RAM: 512MB
  - WiFi: 802.11 b/g/n
  - Note: Uses same core as Pi 3, so RASPPI=3 for Circle builds

### Audio/Display HAT
- **Pimoroni Pirate Audio Line-Out HAT**
  - DAC: PCM5100A (24-bit, up to 384kHz, I2S interface)
  - Display: ST7789 240x240 RGB SPI LCD
  - 4x GPIO buttons (directly directly directly directly directly directly directly directly directly directly directly directly GPIO directly directly directly directly directly on GPIO 5, 6, 16, 24)
  - I2S Pins: BCK=18, LRCK=19, Data=21
  - SPI Pins: DC=9, CS=7 (CE1), Backlight=13
  - **Important**: PCM5100A is simpler than PCM5122 - no I2C config needed, auto-configures from I2S stream

### Serial Debug Interface (for bootloader)
- **Seeed Xiao RP2040** configured as USB-to-Serial bridge
  - D6 (GPIO0) = UART TX → connects to Pi GPIO 15 (RX)
  - D7 (GPIO1) = UART RX → connects to Pi GPIO 14 (TX)
  - GND → Pi GND
  - Needs Picoprobe firmware or MicroPython UART bridge
  - **Do NOT connect 5V to Pi**

---

## Project Goals

### Functional Requirements
1. Load WAV drum samples from SD card (FAT32)
2. Trigger samples via MIDI input or pre-programmed patterns
3. Mix 8-16 simultaneous voices
4. Output audio through Pirate Audio HAT (I2S → PCM5100A)
5. Display UI on ST7789 screen
6. Control via onboard buttons
7. Optional: Web interface for sample upload/pattern editing via WiFi
8. Sub-second boot time (bare metal advantage)

### Learning Goals
- Bare metal ARM programming
- DMA-driven audio
- I2S protocol
- Real-time constraints without OS
- Cross-compilation toolchains

---

## Technology Decision: Circle Framework

After evaluating options (Linux/ALSA, Elk Audio OS port, pure bare metal), **Circle** is the optimal choice:

### What is Circle?
- C++ bare metal environment for Raspberry Pi (no Linux kernel)
- GPL 3.0 licensed, actively maintained by rsta2
- GitHub: https://github.com/rsta2/circle
- Documentation: https://circle-rpi.readthedocs.io

### Why Circle?
| Factor | Status |
|--------|--------|
| Pi Zero 2 W support | ✅ Explicitly tested |
| I2S audio (CI2SSoundDevice) | ✅ Built-in |
| PCM5100A DAC | ✅ Compatible (simpler than supported PCM5122) |
| ST7789 display | ✅ CST7789Display driver exists |
| GPIO buttons | ✅ Full support with interrupts |
| USB MIDI | ✅ CUSBMIDIDevice class |
| FAT32/SD card | ✅ FatFs filesystem driver |
| WiFi + HTTP | ✅ Available (wpa_supplicant ported) |
| Multi-core | ✅ Supported |

### Proven Audio Projects on Circle
1. **MiniSynth Pi** (https://github.com/rsta2/minisynth) - Virtual analog synth by Circle's author
2. **MiniDexed** (https://github.com/probonopd/MiniDexed) - DX7 FM synth, runs on Pi Zero 2 W

---

## Starting Point: MiniSynth Pi

We chose **MiniSynth** over MiniDexed as the starting codebase because:

| Factor | MiniSynth | MiniDexed |
|--------|-----------|-----------|
| Author | rsta2 (Circle's creator) | Community project |
| Code complexity | ~3,000 lines | ~15,000+ lines |
| Circle version | Always current | Slightly behind |
| GUI | LVGL (supports ST7789) | HD44780 LCD |
| Learning curve | Gentle | Steep |

### What to Keep vs Replace from MiniSynth

**KEEP:**
- CKernel boot sequence
- I2S audio output (CI2SSoundDevice)
- USB MIDI input (CUSBMIDIDevice)
- FatFs filesystem
- LVGL GUI framework
- Multi-core support

**REPLACE:**
- Oscillator/VCO classes → Sample loader + player
- Filter (VCF) classes → Simple mixer
- Envelope generators → (optional) amp envelopes
- LFO modulation → Sequencer/pattern engine
- Patch management → Kit/pattern management
- MIDI note → synth voice → MIDI note → sample trigger

---

## Proposed Architecture

### Multi-Core Layout
```
Core 0: Main sequencer logic, pattern playback, UI state machine
Core 1: Audio engine - sample mixing, DMA buffer filling
Core 2: Display updates - ST7789 rendering
Core 3: Network - HTTP server for web interface
```

### Sample Engine (Core Component to Build)
```cpp
class CSampleVoice {
    int16_t* m_pSampleData;    // WAV data in memory
    unsigned m_nSampleLength;
    unsigned m_nPlayPosition;
    bool     m_bPlaying;
    float    m_fVelocity;
    
public:
    void Trigger(float velocity) {
        m_nPlayPosition = 0;
        m_bPlaying = true;
        m_fVelocity = velocity;
    }
    
    int16_t GetNextSample() {
        if (!m_bPlaying) return 0;
        if (m_nPlayPosition >= m_nSampleLength) {
            m_bPlaying = false;
            return 0;
        }
        return m_pSampleData[m_nPlayPosition++] * m_fVelocity;
    }
};

class CDrumKit {
    CSampleVoice m_Voices[16];  // Kick, snare, hats, etc.
    
    void GetChunk(int16_t* pBuffer, unsigned nChunkSize) {
        for (unsigned i = 0; i < nChunkSize; i++) {
            int32_t mix = 0;
            for (auto& voice : m_Voices) {
                mix += voice.GetNextSample();
            }
            pBuffer[i] = Clamp16(mix);  // Simple saturation
        }
    }
};
```

---

## Development Environment Setup

### 1. Install ARM Cross-Compiler (Ubuntu/Debian/WSL)
```bash
sudo apt update
sudo apt install git make gcc-arm-none-eabi build-essential
```

### 2. Clone MiniSynth with Submodules
```bash
git clone https://github.com/rsta2/minisynth.git
cd minisynth
git submodule update --init
cd circle
git submodule update --init addon/lvgl/lvgl
cd ..
```

### 3. Configure for Pi Zero 2 W
```bash
# 32-bit build (recommended to start)
./configure 3 arm-none-eabi-

# OR 64-bit build
./configure 3 arm-none-eabi- 64
```

### 4. Build Everything
```bash
./makeall clean
./makeall
```

### 5. Output
- 32-bit: `src/kernel8-32.img`
- 64-bit: `src/kernel8.img`

---

## SD Card Setup (First Boot)

### Get Pi Firmware
```bash
cd circle/boot
make
```

### Copy to FAT32 SD Card
```bash
# Files needed:
cp bootcode.bin /path/to/sdcard/
cp start.elf /path/to/sdcard/
cp fixup.dat /path/to/sdcard/
cp config.txt /path/to/sdcard/      # Use config32.txt or config64.txt
cp cmdline.txt /path/to/sdcard/     # From minisynth/config/
cp ../src/kernel8-32.img /path/to/sdcard/
```

---

## Serial Bootloader Setup (Fast Iteration)

The serial bootloader allows uploading new kernels in ~2-3 seconds without swapping SD cards.

### Xiao RP2040 Firmware Setup

**Option A: Picoprobe (Recommended)**
1. Download `picoprobe.uf2` from Raspberry Pi GitHub releases
2. Hold BOOT button on Xiao while plugging into USB
3. Drag `.uf2` file to the RPI-RP2 drive that appears
4. Done - enumerates as USB CDC serial port

**Option B: MicroPython UART Bridge**
```python
# main.py on the Xiao
import select
import sys
from machine import UART, Pin

uart = UART(0, baudrate=115200, tx=Pin(0), rx=Pin(1))

while True:
    if select.select([sys.stdin], [], [], 0)[0]:
        uart.write(sys.stdin.read(1))
    if uart.any():
        sys.stdout.write(uart.read(1))
```

### Wiring: Xiao RP2040 → Pi Zero 2 W
```
Xiao RP2040                Pi Zero 2 W
───────────                ───────────
D6 (TX)  ────────────────► GPIO 15 (RX) - Physical Pin 10
D7 (RX)  ◄──────────────── GPIO 14 (TX) - Physical Pin 8
GND      ◄────────────────► GND         - Physical Pin 6

⚠️  Do NOT connect 5V to the Pi!
```

### Circle Bootloader Setup
```bash
# Build the bootloader
cd circle/tools/bootloader
make RASPPI=3

# Copy bootloader kernel to SD card (one time)
cp kernel8-32.img /path/to/sdcard/

# Build flashy tool
cd ../flashy
make
```

### Development Workflow
```bash
# After code changes:
cd minisynth
./makeall

# Upload via serial (~2-3 seconds)
cd circle/tools/flashy
./flashy /dev/ttyACM0 ../../src/kernel8-32.img

# Pi reboots with new code, serial output visible in terminal
```

### Test Serial Connection
```bash
# Find device
ls /dev/ttyACM*

# Open terminal
screen /dev/ttyACM0 115200
# or
minicom -D /dev/ttyACM0 -b 115200
```

---

## Implementation Roadmap

### Phase 1: Hello World (1 weekend)
- [ ] Set up Circle build environment
- [ ] Compile and boot basic kernel
- [ ] Verify serial output
- [ ] Blink LED or display test pattern

### Phase 2: Audio Output (1-2 weekends)
- [ ] Initialize I2S interface for PCM5100A
- [ ] Generate test tone (sine wave)
- [ ] Verify DMA buffer management
- [ ] Confirm audio through Pirate Audio line-out

### Phase 3: Sample Playback (1-2 weekends)
- [ ] Load WAV files from SD card
- [ ] Parse WAV headers
- [ ] Implement sample voice class
- [ ] Implement multi-voice mixer
- [ ] Trigger samples from code/buttons

### Phase 4: UI (1-2 weekends)
- [ ] ST7789 display initialization
- [ ] Button input handling with debouncing
- [ ] Basic menu system
- [ ] Sample/kit selection UI

### Phase 5: Sequencer (1-2 weekends)
- [ ] Pattern storage format
- [ ] Step sequencer playback
- [ ] Tempo control with accurate timing
- [ ] MIDI input support (optional)

### Phase 6: Web Interface (1 weekend)
- [ ] WiFi connection setup
- [ ] HTTP server for control
- [ ] Sample upload via browser
- [ ] Pattern editing UI

---

## Key Resources

### Circle
- Repository: https://github.com/rsta2/circle
- Documentation: https://circle-rpi.readthedocs.io
- Discussions: https://github.com/rsta2/circle/discussions

### Reference Projects
- MiniSynth: https://github.com/rsta2/minisynth
- MiniDexed: https://github.com/probonopd/MiniDexed
- MiniDexed Wiki: https://github.com/probonopd/MiniDexed/wiki

### Hardware Docs
- BCM2835 ARM Peripherals (applies to BCM2837): https://www.raspberrypi.org/app/uploads/2012/02/BCM2835-ARM-Peripherals.pdf
- PCM5100A Datasheet: Available from TI website
- Pirate Audio Pinout: https://pinout.xyz/pinout/pirate_audio_line_out

---

## Notes on QEMU Emulation

QEMU supports Pi 2/3 emulation but **does NOT emulate**:
- I2S audio (critical for this project)
- SPI (needed for ST7789 display)
- DMA
- WiFi

Therefore, **real hardware is required** for testing audio. The serial bootloader is the recommended development approach.

---

## Alternative Approaches Considered (and rejected)

| Approach | Why Not |
|----------|---------|
| Linux + Python | Too slow boot, not challenging enough |
| Linux + C/ALSA | Still 15-20s boot, less educational |
| Elk Audio OS | Massive overkill, weeks of porting, designed for VST hosting |
| Pure bare metal (no Circle) | Reinventing the wheel, Circle already solves hard problems |

---

## First Steps for Claude Code Agent

1. **Verify toolchain**: `arm-none-eabi-gcc --version`
2. **Clone and build MiniSynth** to verify environment works
3. **Set up Xiao RP2040** with Picoprobe firmware
4. **Wire serial connection** and test with `screen`
5. **Set up Circle bootloader** for fast iteration
6. **Boot MiniSynth** on Pi Zero 2 W, verify audio output
7. **Begin modifying** - start by understanding the audio callback chain

Good luck! This is a genuinely interesting project that will teach you a lot about embedded systems and real-time audio.
