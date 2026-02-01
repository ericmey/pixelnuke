//
// kernel.cpp
//
// Pixelnuke Bootloader - Serial + TFTP firmware update system
// with A/B partition support
//
// Copyright (C) 2025
//

#include "kernel.h"
#include "tftpbootserver.h"
#include <circle/machineinfo.h>
#include <circle/string.h>
#include <circle/util.h>
#include <circle/startup.h>
#include <assert.h>

static const char FromKernel[] = "kernel";

// Static members
boolean CKernel::s_bRebootRequested = FALSE;
char CKernel::s_cTargetPartition    = 'A';
char CKernel::s_cCurrentPartition   = 'A';

CKernel::CKernel(void)
    : m_Screen(m_Options.GetWidth(), m_Options.GetHeight())
    , m_Timer(&m_Interrupt)
    , m_Logger(m_Options.GetLogLevel(), &m_Timer)
    , m_USBHCI(&m_Interrupt, &m_Timer)
    , m_EMMC(&m_Interrupt, &m_Timer, 0)
    , m_PartitionManager(&m_EMMC, "emmc1")
    , m_WLAN(FIRMWARE_PATH)
    , m_Net(0, 0, 0, 0, "pixelnuke", NetDeviceTypeWLAN)
    , m_WPASupplicant(CONFIG_FILE)
    , m_bNetworkUp(FALSE)
    , m_bHaveWiFiConfig(FALSE)
    , m_cCurrentPartition('A')
{
}

CKernel::~CKernel(void) {}

boolean CKernel::Initialize(void)
{
	boolean bOK = TRUE;

	if (bOK)
	{
		bOK = m_Screen.Initialize();
	}

	if (bOK)
	{
		bOK = m_Serial.Initialize(115200);
	}

	if (bOK)
	{
		CDevice *pTarget = m_DeviceNameService.GetDevice(m_Options.GetLogDevice(), FALSE);
		if (pTarget == 0)
		{
			pTarget = &m_Screen;
		}

		bOK = m_Logger.Initialize(pTarget);
	}

	if (bOK)
	{
		bOK = m_Interrupt.Initialize();
	}

	if (bOK)
	{
		bOK = m_Timer.Initialize();
	}

	if (bOK)
	{
		bOK = m_USBHCI.Initialize();
	}

	// Initialize SD card
	if (bOK)
	{
		bOK = m_EMMC.Initialize();
	}

	// Initialize partition manager (parses MBR, registers emmc1-1, emmc1-2, emmc1-3, emmc1-4)
	if (bOK)
	{
		if (!m_PartitionManager.Initialize())
		{
			m_Logger.Write(FromKernel, LogWarning, "Partition manager init failed");
			// Continue anyway - we can still boot, just can't write to alt partition
		}
	}

	// Mount filesystem (current boot partition is already "SD:" via FatFs volume mapping)
	if (bOK)
	{
		if (f_mount(&m_FileSystem, "SD:", 1) != FR_OK)
		{
			m_Logger.Write(FromKernel, LogError, "Cannot mount SD card");
			bOK = FALSE;
		}
	}

	// Detect which partition we booted from
	if (bOK)
	{
		m_cCurrentPartition = DetectCurrentPartition();
		s_cCurrentPartition = m_cCurrentPartition;
		m_Logger.Write(FromKernel, LogNotice, "Booted from partition %c",
			       m_cCurrentPartition);
	}

	// Check for WiFi config
	if (bOK)
	{
		FIL ConfigFile;
		if (f_open(&ConfigFile, CONFIG_FILE, FA_READ) == FR_OK)
		{
			f_close(&ConfigFile);
			m_bHaveWiFiConfig = TRUE;
			m_Logger.Write(FromKernel, LogNotice, "Found wpa_supplicant.conf");
		}
		else
		{
			m_Logger.Write(FromKernel, LogWarning,
				       "No wpa_supplicant.conf - WiFi disabled");
		}
	}

	// Initialize WiFi if config exists
	if (bOK && m_bHaveWiFiConfig)
	{
		bOK = m_WLAN.Initialize();
		if (!bOK)
		{
			m_Logger.Write(FromKernel, LogWarning,
				       "WLAN init failed, continuing without WiFi");
			bOK		  = TRUE; // Continue without WiFi
			m_bHaveWiFiConfig = FALSE;
		}
	}

	return bOK;
}

TShutdownMode CKernel::Run(void)
{
	m_Logger.Write(FromKernel, LogNotice, "Pixelnuke Bootloader");
	m_Logger.Write(FromKernel, LogNotice, "Compile time: " __DATE__ " " __TIME__);
	m_Logger.Write(FromKernel, LogNotice, "Current partition: %c", m_cCurrentPartition);
	DisplayStatus("Pixelnuke Bootloader");

	// Send serial bootloader ready signal and wait for upload
	m_Logger.Write(FromKernel, LogNotice, "Waiting %d seconds for serial upload...",
		       SERIAL_WAIT_SECONDS);
	DisplayStatus("Serial upload...");
	SendSerialReady();

	if (WaitForSerialUpload())
	{
		// Serial upload handled, reboot
		m_Logger.Write(FromKernel, LogNotice, "Serial upload complete, rebooting...");
		return ShutdownReboot;
	}

	// Connect to WiFi if configured
	if (m_bHaveWiFiConfig)
	{
		m_Logger.Write(FromKernel, LogNotice, "Connecting to WiFi...");
		DisplayStatus("Connecting WiFi...");

		if (!m_Net.Initialize(FALSE))
		{
			m_Logger.Write(FromKernel, LogWarning, "Network init failed");
		}
		else if (!m_WPASupplicant.Initialize())
		{
			m_Logger.Write(FromKernel, LogWarning, "WPA supplicant init failed");
		}
		else
		{
			// Wait for network connection (up to 30 seconds)
			unsigned nTimeout = 300; // 30 seconds in 100ms intervals
			while (!m_Net.IsRunning() && nTimeout > 0)
			{
				m_Scheduler.MsSleep(100);
				nTimeout--;
			}

			if (m_Net.IsRunning())
			{
				m_bNetworkUp = TRUE;

				CString IPString;
				m_Net.GetConfig()->GetIPAddress()->Format(&IPString);
				m_Logger.Write(FromKernel, LogNotice, "Network up: %s",
					       (const char *)IPString);

				// Show TFTP command
				m_Logger.Write(
					FromKernel, LogNotice,
					"TFTP: tftp -m binary %s -c put pxnk_pixelnuke_kernel.img",
					(const char *)IPString);

				DisplayStatus((const char *)IPString);
			}
			else
			{
				m_Logger.Write(FromKernel, LogWarning, "WiFi connection timeout");
				DisplayStatus("WiFi timeout");
			}
		}
	}

	// Start TFTP server if network is up
	if (m_bNetworkUp)
	{
		m_Logger.Write(FromKernel, LogNotice, "Starting TFTP server...");
		new CTFTPBootServer(&m_Net, KERNEL_MAX_SIZE);
	}

	m_Logger.Write(FromKernel, LogNotice, "Waiting for firmware upload...");

	// Main loop - wait for reboot request from TFTP upload
	for (unsigned nCount = 0; !IsRebootRequested(); nCount++)
	{
		m_Screen.Rotor(0, nCount);
		m_Scheduler.Yield();
	}

	// Firmware was uploaded, prepare for reboot
	char cTarget = GetTargetPartition();
	m_Logger.Write(FromKernel, LogNotice, "Firmware uploaded to partition %c", cTarget);

	// Set tryboot flag if booting to alternate partition
	if (cTarget != m_cCurrentPartition)
	{
		m_Logger.Write(FromKernel, LogNotice, "Setting tryboot flag...");
		if (!SetTrybootFlag(TRUE))
		{
			m_Logger.Write(FromKernel, LogWarning, "Failed to set tryboot flag");
		}
	}

	m_Logger.Write(FromKernel, LogNotice, "Rebooting...");
	DisplayStatus("Rebooting...");
	m_Scheduler.Sleep(1);

	return ShutdownReboot;
}

char CKernel::DetectCurrentPartition(void)
{
	// Read autoboot.txt from PXNK_BOOT (SD:) to determine which partition we booted from
	// boot_partition=2 means A, boot_partition=3 means B
	FIL File;
	if (f_open(&File, "SD:/autoboot.txt", FA_READ) == FR_OK)
	{
		char Buffer[256];
		UINT nRead;
		if (f_read(&File, Buffer, sizeof(Buffer) - 1, &nRead) == FR_OK && nRead > 0)
		{
			Buffer[nRead] = '\0';
			f_close(&File);

			// Look for boot_partition= in [all] section
			const char *pBootPart = strstr(Buffer, "boot_partition=");
			if (pBootPart != 0)
			{
				int nPartition = pBootPart[15] - '0'; // Get digit after '='
				if (nPartition == 2)
				{
					return 'A';
				}
				else if (nPartition == 3)
				{
					return 'B';
				}
			}
		}
		else
		{
			f_close(&File);
		}
	}

	// Default to A if we can't determine
	m_Logger.Write(FromKernel, LogWarning, "Could not detect partition, assuming A");
	return 'A';
}

boolean CKernel::SetTrybootFlag(boolean bEnable)
{
	// Try the mailbox property approach first
	// Tag 0x00038064 with value 1 enables tryboot
	CBcmPropertyTags Tags;

	struct TTrybootTag
	{
		TPropertyTag Tag;
		u32 nValue;
	} PACKED;

	TTrybootTag TrybootTag;
	TrybootTag.Tag.nTagId	     = PROPTAG_SET_REBOOT_FLAGS;
	TrybootTag.Tag.nValueBufSize = sizeof(TrybootTag.nValue);
	TrybootTag.Tag.nValueLength  = sizeof(TrybootTag.nValue);
	TrybootTag.nValue	     = bEnable ? 1 : 0;

	boolean bMailboxOK = Tags.GetTag(PROPTAG_SET_REBOOT_FLAGS, &TrybootTag, sizeof(TrybootTag),
					 sizeof(TrybootTag.nValue));

	if (bMailboxOK)
	{
		CLogger::Get()->Write(FromKernel, LogNotice, "Tryboot flag set via mailbox");
	}
	else
	{
		CLogger::Get()->Write(FromKernel, LogWarning, "Mailbox tryboot flag failed");
	}

	// Also directly modify autoboot.txt as a fallback
	// This ensures partition switch works even if mailbox flag isn't honored
	char cTarget = (s_cCurrentPartition == 'A') ? 'B' : 'A';
	int nTargetPartition = (cTarget == 'A') ? 2 : 3;

	CLogger::Get()->Write(FromKernel, LogNotice, "Updating autoboot.txt to partition %d",
			      nTargetPartition);

	// Write new autoboot.txt - SD: is mapped to partition 1 (PXNK_BOOT)
	FIL File;
	FRESULT Result = f_open(&File, "SD:/autoboot.txt", FA_WRITE | FA_CREATE_ALWAYS);
	if (Result != FR_OK)
	{
		CLogger::Get()->Write(FromKernel, LogError, "Cannot open autoboot.txt (error %d)",
				      Result);
		return bMailboxOK;
	}

	// Write the autoboot.txt content with target partition
	CString Content;
	Content.Format("# Pixelnuke A/B Boot Selector\n"
		       "[all]\n"
		       "tryboot_a_b=1\n"
		       "boot_partition=%d\n"
		       "\n"
		       "[tryboot]\n"
		       "boot_partition=%d\n",
		       nTargetPartition,
		       (nTargetPartition == 2) ? 3 : 2);

	UINT nWritten;
	Result = f_write(&File, (const char *)Content, Content.GetLength(), &nWritten);
	f_close(&File);

	if (Result != FR_OK || nWritten != Content.GetLength())
	{
		CLogger::Get()->Write(FromKernel, LogError, "Failed to write autoboot.txt");
		return bMailboxOK;
	}

	CLogger::Get()->Write(FromKernel, LogNotice, "autoboot.txt updated for partition %c",
			      cTarget);
	return TRUE;
}

boolean CKernel::UpdateAutoboot(char cNewDefault)
{
	// This would update autoboot.txt on partition 0 to change default boot partition
	// For now, tryboot handles temporary switch; permanent switch done after confirmed success
	// TODO: Implement when needed for permanent partition switch
	return TRUE;
}

boolean CKernel::WriteFirmwareToPartition(const char *pPartition, const u8 *pData, unsigned nSize)
{
	// TODO: Mount the target partition and write kernel8.img
	// This requires mounting the alternate partition's filesystem
	// For now, return TRUE as placeholder - actual write will be implemented
	// when we have multi-partition mount support
	(void)pPartition;
	(void)pData;
	(void)nSize;
	return TRUE;
}

void CKernel::SendSerialReady(void)
{
	// Send Circle bootloader protocol ready signal (IHEX-F)
	m_Serial.Write("IHEX-F\r\n", 8);
}

boolean CKernel::WaitForSerialUpload(void)
{
	// Wait for serial upload command
	// The host sends specific pattern to initiate upload
	// For now, just wait the timeout period

	unsigned nTimeout = SERIAL_WAIT_SECONDS * 10; // 100ms intervals
	u8 Buffer[16];

	while (nTimeout > 0)
	{
		int nReceived = m_Serial.Read(Buffer, sizeof(Buffer));
		if (nReceived > 0)
		{
			// Check for upload initiation (simplified)
			// Full implementation would handle IHEX protocol
			// For now, any data during wait period triggers upload mode
			// The actual serial upload is handled elsewhere
		}
		m_Scheduler.MsSleep(100);
		nTimeout--;
	}

	return FALSE; // No serial upload, continue to network
}

void CKernel::DisplayStatus(const char *pMessage)
{
	// Display status on screen
	m_Screen.Write(pMessage, strlen(pMessage));
	m_Screen.Write("\n", 1);
}

// Static methods for TFTP server callback
void CKernel::RequestReboot(char cTargetPartition)
{
	s_cTargetPartition = cTargetPartition;
	s_bRebootRequested = TRUE;
}

boolean CKernel::IsRebootRequested(void)
{
	return s_bRebootRequested;
}

char CKernel::GetTargetPartition(void)
{
	return s_cTargetPartition;
}

char CKernel::GetCurrentPartition(void)
{
	return s_cCurrentPartition;
}

char CKernel::GetAlternatePartition(void)
{
	return (s_cCurrentPartition == 'A') ? 'B' : 'A';
}

boolean CKernel::WriteFirmware(char cPartition, const u8 *pData, unsigned nSize)
{
	// Map partition letter to FatFs volume number
	// Volume 0 (SD:) = PXNK_BOOT (partition 1)
	// Volume 1 (1:)  = PXNK_A (partition 2)
	// Volume 2 (2:)  = PXNK_B (partition 3)
	const char *pVolume;
	if (cPartition == 'A')
	{
		pVolume = "1:";
	}
	else if (cPartition == 'B')
	{
		pVolume = "2:";
	}
	else
	{
		CLogger::Get()->Write(FromKernel, LogError, "Invalid partition: %c", cPartition);
		return FALSE;
	}

	CLogger::Get()->Write(FromKernel, LogNotice, "Mounting partition %c (%s)...",
			      cPartition, pVolume);

	// Mount the target partition
	static FATFS AltFileSystem;
	FRESULT Result = f_mount(&AltFileSystem, pVolume, 1);
	if (Result != FR_OK)
	{
		CLogger::Get()->Write(FromKernel, LogError, "Failed to mount %s (error %d)",
				      pVolume, Result);
		return FALSE;
	}

	// Build the full path
	CString KernelPath;
	KernelPath.Format("%s/kernel8.img", pVolume);

	CLogger::Get()->Write(FromKernel, LogNotice, "Writing %u bytes to %s...",
			      nSize, (const char *)KernelPath);

	// Open file for writing
	FIL File;
	Result = f_open(&File, (const char *)KernelPath, FA_WRITE | FA_CREATE_ALWAYS);
	if (Result != FR_OK)
	{
		CLogger::Get()->Write(FromKernel, LogError, "Failed to create %s (error %d)",
				      (const char *)KernelPath, Result);
		f_mount(0, pVolume, 0);
		return FALSE;
	}

	// Write the firmware data
	UINT nWritten;
	Result = f_write(&File, pData, nSize, &nWritten);
	if (Result != FR_OK || nWritten != nSize)
	{
		CLogger::Get()->Write(FromKernel, LogError, "Write failed (error %d, wrote %u/%u)",
				      Result, nWritten, nSize);
		f_close(&File);
		f_mount(0, pVolume, 0);
		return FALSE;
	}

	// Close and sync
	f_close(&File);
	f_mount(0, pVolume, 0);

	CLogger::Get()->Write(FromKernel, LogNotice, "Firmware written successfully to partition %c",
			      cPartition);

	return TRUE;
}
