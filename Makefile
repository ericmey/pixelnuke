#
# Pixelnuke - Bare Metal Drum Machine
#
# Top-level Makefile for building bootloader and application
#

.PHONY: all bootloader app libs clean clean-all install flash help

# Default target
all: bootloader

# Build the bootloader
bootloader: libs
	$(MAKE) -C src/bootloader

# Build the main application (when implemented)
app: libs
	@if [ -d src/app ]; then \
		$(MAKE) -C src/app; \
	else \
		echo "Application not yet implemented"; \
	fi

# Apply patches to Circle for multi-partition support
patch-circle:
	@if ! grep -q "emmc1-1" circle/addon/fatfs/diskio.cpp 2>/dev/null; then \
		echo "Applying Circle multi-partition patch..."; \
		cd circle && git apply ../patches/circle-fatfs-multipartition.patch; \
	else \
		echo "Circle patch already applied"; \
	fi

# Build all Circle libraries (first-time setup)
libs: patch-circle
	cd circle && ./makeall
	$(MAKE) -C circle/addon/SDCard
	$(MAKE) -C circle/addon/fatfs
	cd circle/addon/wlan && ./makeall

# Download WiFi firmware
wifi-firmware:
	$(MAKE) -C circle/addon/wlan/firmware

# Clean bootloader build
clean:
	$(MAKE) -C src/bootloader clean
	@if [ -d src/app ]; then $(MAKE) -C src/app clean; fi

# Clean everything including Circle libraries
clean-all: clean
	cd circle && ./makeall clean
	$(MAKE) -C circle/addon/SDCard clean
	$(MAKE) -C circle/addon/fatfs clean
	cd circle/addon/wlan && ./makeall clean

# Install bootloader to SD card
install: bootloader
ifndef SDCARD
	$(error SDCARD not defined. Use: make install SDCARD=/Volumes/BOOT)
endif
	cp src/bootloader/kernel8.img $(SDCARD)/
	@echo "Installed bootloader to $(SDCARD)/kernel8.img"

# Flash bootloader via serial
flash: bootloader
	./flash.sh

# Partition SD card (macOS)
partition-sd:
ifndef DISK
	$(error DISK not defined. Use: make partition-sd DISK=/dev/diskN)
endif
	./tools/macos/partition-sd.sh $(DISK)

# Setup A/B boot partitions
setup-ab: bootloader
ifndef BOOT
	$(error BOOT, A, B not defined. Use: make setup-ab BOOT=/Volumes/PXNK_BOOT A=/Volumes/PXNK_A B=/Volumes/PXNK_B)
endif
ifndef A
	$(error A not defined)
endif
ifndef B
	$(error B not defined)
endif
	./boot/setup-ab-boot.sh $(BOOT) $(A) $(B)

# Prepare SD card with all boot files (legacy single-partition)
prepare-sd:
ifndef SDCARD
	$(error SDCARD not defined. Use: make prepare-sd SDCARD=/Volumes/BOOT)
endif
	./boot/prepare-sd.sh $(SDCARD)

# Help
help:
	@echo "Pixelnuke Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all           - Build bootloader (default)"
	@echo "  bootloader    - Build the bootloader"
	@echo "  app           - Build the main application"
	@echo "  libs          - Build Circle libraries (first-time setup)"
	@echo "  wifi-firmware - Download WiFi firmware files"
	@echo "  clean         - Clean bootloader/app builds"
	@echo "  clean-all     - Clean everything including Circle"
	@echo ""
	@echo "Deployment:"
	@echo "  install SDCARD=path  - Copy bootloader to SD card"
	@echo "  prepare-sd SDCARD=path - Prepare SD card with all files"
	@echo "  flash         - Flash bootloader via serial"
	@echo ""
	@echo "First-time setup:"
	@echo "  1. Configure Circle: cd circle && ./configure -r 3 -p aarch64-none-elf- --multicore -f"
	@echo "  2. Build libraries:  make libs (automatically applies patches)"
	@echo "  3. Download WiFi FW: make wifi-firmware"
	@echo "  4. Build bootloader: make bootloader"
	@echo "  5. Partition SD:     make partition-sd DISK=/dev/diskN (macOS)"
	@echo "  6. Setup A/B boot:   make setup-ab BOOT=/Volumes/PXNK_BOOT A=/Volumes/PXNK_A B=/Volumes/PXNK_B"
