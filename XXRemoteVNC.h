//
//  XXRemoteX11Daemon.h
//  osx2x
//
// Copyright (c) Michael Dales 2002, 2003
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of Michael Dales nor the names of its contributors may be
// used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
// IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED.  IN NO EVENT S HALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS I NTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//


#import "XXAbstractRemote.h"
#import <Foundation/Foundation.h>
#import <time.h>

@interface XXRemoteVNC : NSObject <XXAbstractRemote>
{
    int fd_socket;
    NSFileHandle *sock;
    NSRect displaySize;

	// debugging
	time_t lastSendTime;

	// we need to maintain the state of the mouse, because
	// when we receive an incremental change we need to 
	// resend the entire state
	NSPoint mousePosition;
	int mouseButtons;
        bool shifted_left;
        bool shifted_right;
		bool alted_right;
}

- initWithHostName: (NSString*)hostname
      withPassword: (NSString*)password;

- (void)sendMouseMessage;

- (void)sendControlAltDelete;

- (void)suck;

- (void)send: (void *)msg
	  length: (unsigned int)length;

- (void)recv: (void *)msg
	  length: (unsigned int)length;

@end
