#
# Makefile for Pixelnuke Bootloader
#
# Minimal bootloader with Serial + TFTP for firmware updates
# HTTP web interface will be in the application layer
#

CIRCLEHOME = ../../circle

# Pi Zero 2 W uses RASPPI=3 (BCM2710A1 = cut-down BCM2837)
RASPPI = 3

# Use 64-bit (AArch64)
AARCH = 64

OBJS = main.o kernel.o tftpbootserver.o

# Libraries required for bootloader functionality
# Order matters - dependencies must come after dependents
LIBS = $(CIRCLEHOME)/addon/wlan/hostap/wpa_supplicant/libwpa_supplicant.a \
       $(CIRCLEHOME)/addon/wlan/libwlan.a \
       $(CIRCLEHOME)/addon/fatfs/libfatfs.a \
       $(CIRCLEHOME)/addon/SDCard/libsdcard.a \
       $(CIRCLEHOME)/lib/net/libnet.a \
       $(CIRCLEHOME)/lib/sched/libsched.a \
       $(CIRCLEHOME)/lib/usb/libusb.a \
       $(CIRCLEHOME)/lib/input/libinput.a \
       $(CIRCLEHOME)/lib/fs/libfs.a \
       $(CIRCLEHOME)/lib/libcircle.a

# Include paths for addon libraries
EXTRAINCLUDE = -I $(CIRCLEHOME)/addon -I $(CIRCLEHOME)/addon/fatfs

include $(CIRCLEHOME)/Rules.mk

# Phony targets
.PHONY: libs clean-libs install format format-check lint check

# Build all required libraries
libs:
	cd $(CIRCLEHOME) && ./makeall
	cd $(CIRCLEHOME)/addon/SDCard && make
	cd $(CIRCLEHOME)/addon/fatfs && make
	cd $(CIRCLEHOME)/addon/wlan && ./makeall

# Clean libraries
clean-libs:
	cd $(CIRCLEHOME) && ./makeall clean
	cd $(CIRCLEHOME)/addon/SDCard && make clean
	cd $(CIRCLEHOME)/addon/fatfs && make clean
	cd $(CIRCLEHOME)/addon/wlan && ./makeall clean

# Install to SD card (for single partition legacy mode)
install: $(TARGET).img
ifndef SDCARD
	$(error SDCARD not defined. Use: make install SDCARD=/Volumes/BOOT)
endif
	cp $(TARGET).img $(SDCARD)/kernel8.img
	@echo "Installed to $(SDCARD)/kernel8.img"

-include $(DEPS)

# Code quality targets
SRCS = $(wildcard *.cpp *.h)

# Format code with clang-format
format:
	clang-format -i $(SRCS)

# Check formatting without modifying
format-check:
	clang-format --dry-run --Werror $(SRCS)

# Static analysis with cppcheck
lint:
	cppcheck --enable=warning,style,performance,portability \
		--suppressions-list=.cppcheck-suppressions \
		--error-exitcode=1 \
		-I $(CIRCLEHOME)/include \
		-I $(CIRCLEHOME)/addon \
		$(wildcard *.cpp)

# Run all checks
check: format-check lint
	@echo "All checks passed!"
