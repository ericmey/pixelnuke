//
// kernel.h
//
// Pixelnuke Bootloader - Serial + TFTP firmware update system
// with A/B partition support
//
// Copyright (C) 2025
//

#ifndef _kernel_h
#define _kernel_h

#include <circle/koptions.h>
#include <circle/devicenameservice.h>
#include <circle/screen.h>
#include <circle/serial.h>
#include <circle/exceptionhandler.h>
#include <circle/interrupt.h>
#include <circle/timer.h>
#include <circle/logger.h>
#include <circle/usb/usbhcidevice.h>
#include <circle/sched/scheduler.h>
#include <circle/net/netsubsystem.h>
#include <circle/bcmpropertytags.h>
#include <circle/types.h>
#include <SDCard/emmc.h>
#include <circle/fs/partitionmanager.h>
#include <fatfs/ff.h>
#include <wlan/bcm4343.h>
#include <wlan/hostap/wpa_supplicant/wpasupplicant.h>

// Shutdown modes
enum TShutdownMode
{
	ShutdownNone,
	ShutdownHalt,
	ShutdownReboot
};

// A/B Partition scheme (active partition is mounted as "SD:")
// Partition 1: Boot selector (autoboot.txt) - mounted separately when needed
// Partition 2: Boot A
// Partition 3: Boot B
// Partition 4: User data

#define FIRMWARE_PATH "SD:/firmware/"
#define CONFIG_FILE "SD:/wpa_supplicant.conf"
#define PARTITION_ID_FILE "SD:/.partition_id"

#define TFTP_BOOT_PORT 69
#define SERIAL_WAIT_SECONDS 2

// Tryboot mailbox property tag
#define PROPTAG_SET_REBOOT_FLAGS 0x00038064

class CKernel
{
      public:
	CKernel(void);
	~CKernel(void);

	boolean Initialize(void);

	TShutdownMode Run(void);

      private:
	// Serial bootloader protocol handling
	boolean WaitForSerialUpload(void);
	void SendSerialReady(void);

	// A/B partition management
	char DetectCurrentPartition(void);
	boolean WriteFirmwareToPartition(const char *pPartition, const u8 *pData, unsigned nSize);
	boolean SetTrybootFlag(boolean bEnable);
	boolean UpdateAutoboot(char cNewDefault);

	// Display helpers
	void DisplayStatus(const char *pMessage);

      private:
	// Do not change this order - initialization depends on it
	CKernelOptions m_Options;
	CDeviceNameService m_DeviceNameService;
	CScreenDevice m_Screen;
	CSerialDevice m_Serial;
	CExceptionHandler m_ExceptionHandler;
	CInterruptSystem m_Interrupt;
	CTimer m_Timer;
	CLogger m_Logger;
	CUSBHCIDevice m_USBHCI;
	CEMMCDevice m_EMMC;
	CPartitionManager m_PartitionManager;
	FATFS m_FileSystem;
	CScheduler m_Scheduler;

	// WiFi components
	CBcm4343Device m_WLAN;
	CNetSubSystem m_Net;
	CWPASupplicant m_WPASupplicant;

	// State
	boolean m_bNetworkUp;
	boolean m_bHaveWiFiConfig;
	char m_cCurrentPartition; // 'A' or 'B'

	// Reboot request flag (set by TFTP server after successful upload)
	static boolean s_bRebootRequested;
	static char s_cTargetPartition; // Partition to boot after reboot

      public:
	// Called by TFTP server after firmware upload
	static void RequestReboot(char cTargetPartition);
	static boolean IsRebootRequested(void);
	static char GetTargetPartition(void);

	// Get current and alternate partition identifiers
	static char GetCurrentPartition(void);
	static char GetAlternatePartition(void);

	// Write firmware to specified partition
	static boolean WriteFirmware(char cPartition, const u8 *pData, unsigned nSize);

      private:
	static char s_cCurrentPartition;
};

#endif
