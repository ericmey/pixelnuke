//
// tftpbootserver.h
//
// TFTP-based firmware upload server for A/B partition scheme
// Writes received firmware to the alternate partition
//
// Copyright (C) 2025
//

#ifndef _tftpbootserver_h
#define _tftpbootserver_h

#include "kernel.h"
#include <circle/net/netsubsystem.h>
#include <circle/net/tftpdaemon.h>
#include <circle/types.h>

class CTFTPBootServer : public CTFTPDaemon
{
      public:
	CTFTPBootServer(CNetSubSystem *pNetSubSystem, size_t nMaxKernelSize);
	~CTFTPBootServer(void) override;

	boolean FileOpen(const char *pFileName) override;
	boolean FileCreate(const char *pFileName) override;
	boolean FileClose(void) override;
	int FileRead(void *pBuffer, unsigned nCount) override;
	int FileWrite(const void *pBuffer, unsigned nCount) override;

      private:
	size_t m_nMaxKernelSize;

	boolean m_bFileOpen;
	u8 *m_pKernelBuffer;
	unsigned m_nCurrentOffset;
};

#endif
