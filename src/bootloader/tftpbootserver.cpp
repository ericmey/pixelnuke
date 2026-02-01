//
// tftpbootserver.cpp
//
// TFTP-based firmware upload server for A/B partition scheme
// Writes received firmware to the alternate partition
//
// Copyright (C) 2025
//

#include "tftpbootserver.h"
#include <circle/logger.h>
#include <circle/util.h>
#include <fatfs/ff.h>
#include <assert.h>

// Authentication: filename must start with "pxnk_<password>_"
#define TFTP_AUTH_PREFIX "pxnk_pixelnuke_"

static const char FromBootServer[] = "tftpboot";

CTFTPBootServer::CTFTPBootServer(CNetSubSystem *pNetSubSystem, size_t nMaxKernelSize)
    : CTFTPDaemon(pNetSubSystem)
    , m_nMaxKernelSize(nMaxKernelSize)
    , m_bFileOpen(FALSE)
    , m_pKernelBuffer(0)
    , m_nCurrentOffset(0)
{
}

CTFTPBootServer::~CTFTPBootServer(void)
{
	assert(!m_bFileOpen);

	delete[] m_pKernelBuffer;
	m_pKernelBuffer = 0;
}

boolean CTFTPBootServer::FileOpen(const char *pFileName)
{
	// Read not supported
	return FALSE;
}

boolean CTFTPBootServer::FileCreate(const char *pFileName)
{
	if (m_bFileOpen)
	{
		return FALSE;
	}

	assert(pFileName != 0);

	// Check for authentication prefix (pxnk_<password>_)
	size_t nPrefixLen = strlen(TFTP_AUTH_PREFIX);
	if (strncmp(pFileName, TFTP_AUTH_PREFIX, nPrefixLen) != 0)
	{
		CLogger::Get()->Write(FromBootServer, LogWarning,
				      "Rejected file: %s (invalid prefix)", pFileName);
		return FALSE;
	}

	// Get the actual filename after the prefix
	const char *pActualName = pFileName + nPrefixLen;
	size_t nLen		= strlen(pActualName);
	if (nLen < 4)
	{
		return FALSE;
	}

	static const char FileExt[] = ".img";
	if (strcmp(&pActualName[nLen - (sizeof FileExt - 1)], FileExt) != 0)
	{
		CLogger::Get()->Write(FromBootServer, LogWarning, "Rejected file: %s (not .img)",
				      pFileName);
		return FALSE;
	}

	CLogger::Get()->Write(FromBootServer, LogDebug, "Receiving %s ...", pActualName);

	if (m_pKernelBuffer == 0)
	{
		m_pKernelBuffer = new u8[m_nMaxKernelSize];
		if (m_pKernelBuffer == 0)
		{
			CLogger::Get()->Write(FromBootServer, LogError, "Out of memory");
			return FALSE;
		}
	}

	m_nCurrentOffset = 0;
	m_bFileOpen	 = TRUE;

	return TRUE;
}

boolean CTFTPBootServer::FileClose(void)
{
	assert(m_bFileOpen);

	CLogger::Get()->Write(FromBootServer, LogNotice, "%lu bytes received",
			      (unsigned long)m_nCurrentOffset);

	m_bFileOpen = FALSE;

	if (m_nCurrentOffset > 0)
	{
		// Write firmware to the alternate partition
		char cAltPartition = CKernel::GetAlternatePartition();
		CLogger::Get()->Write(FromBootServer, LogNotice, "Writing to partition %c...",
				      cAltPartition);

		// Write the firmware to the alternate partition
		if (!CKernel::WriteFirmware(cAltPartition, m_pKernelBuffer, m_nCurrentOffset))
		{
			CLogger::Get()->Write(FromBootServer, LogError,
					      "Failed to write firmware to partition %c",
					      cAltPartition);
			return FALSE;
		}

		// Request reboot to the alternate partition
		CKernel::RequestReboot(cAltPartition);

		CLogger::Get()->Write(FromBootServer, LogNotice,
				      "Firmware written successfully, rebooting to partition %c...",
				      cAltPartition);
	}

	return TRUE;
}

int CTFTPBootServer::FileRead(void *pBuffer, unsigned nCount)
{
	// Read not supported
	return -1;
}

int CTFTPBootServer::FileWrite(const void *pBuffer, unsigned nCount)
{
	assert(m_bFileOpen);

	if (m_nCurrentOffset + nCount > m_nMaxKernelSize)
	{
		CLogger::Get()->Write(FromBootServer, LogError, "Firmware too large");
		m_bFileOpen = FALSE;
		return -1;
	}

	assert(pBuffer != 0);
	memcpy(m_pKernelBuffer + m_nCurrentOffset, pBuffer, nCount);
	m_nCurrentOffset += nCount;

	return nCount;
}
