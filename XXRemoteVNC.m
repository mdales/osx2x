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
// PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
// CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
// PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

// major todos:
// - protocol version 3.7 is broken. no tragedy - we just use 3.3, which
//   all servers should speak
// - we should probably wrap the socket with an NSFileHandle from the
//   beginning, and do all IO though that. It'll take care of throwing
//   exceptions for us, too
// - there's a problem with the shift key
// - no copy from the remote display. this would require understanding the 
//   data that comes our way, instead of blindly accepting it
// - error tolerance is basically untested

#import "XXRemoteVNC.h"
#import <unistd.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <netinet/tcp.h>
#import <errno.h>
#import <netdb.h>
#import <strings.h>
#import <fcntl.h>
#import <openssl/des.h>

// XXX: This is a hack as the 10.2 SDK seems to have the wrong header files
#undef des_ecb_encrypt
#undef des_set_key_unchecked

//void des_ecb_encrypt(const_des_cblock *input,des_cblock *output,
//                     des_key_schedule *ks,int enc);
//void des_set_key_unchecked(const_des_cblock *key, des_key_schedule *schedule);

#import "keymap.h"

#define PORT_NUMBER 5900

@implementation XXRemoteVNC

/*******************************
 * stuff to send/receive data, and throw exceptions appropriately
 */

- (void)suck
{
	// dirty hack - read everything possible
	char junk[4096];
	while(recv(fd_socket, junk, sizeof(junk), 0) > 0)
		;
	[sock waitForDataInBackgroundAndNotify];
}

- (void)send: (void *)msg
	  length: (unsigned int)length
{
	int ret = send(fd_socket, (unsigned char *)msg, length, 0);
	if(ret == length) {
		lastSendTime = time(NULL);
		return;
	}

	NSLog(@"sending failed: %0d bytes", (int)length);
	NSLog(@"last successful send: %0d secs ago",
		(int)(time(NULL) - lastSendTime));

	NSException* myException = 
	   [NSException exceptionWithName: @"ConnectionLost"
                               reason: @"Failed To Send Data"
	                         userInfo: nil];
	[myException raise];
}

- (void)recv: (void *)msg
      length: (unsigned int)length
{
	int ret = recv(fd_socket, (unsigned char *)msg, length, 0);
	if(ret == length)
		return;
	
	NSException* myException = 
	   [NSException exceptionWithName: @"ConnectionLost"
                               reason: @"Failed To Receive Data"
	                         userInfo: nil];
	[myException raise];
}
	
/*******************************
 * Connection setup
 */

- initWithHostName: (NSString*)hostname
      withPassword: (NSString*)password
{
    if (!(self = [super init]))
		return self;

	mouseButtons = 0;
	fd_socket = -1;

    struct sockaddr_in addr;
    struct hostent *host;

    NS_DURING
		// try and separate out hostname:displaynumber
		NSArray* addrsplit = [hostname componentsSeparatedByString:@":"];
		int portNumber = PORT_NUMBER;
		if([addrsplit count] > 2) {
			NSLog(@"Not a valid address");
			[self release];
			//[addrsplit release];
			NS_VALUERETURN(nil, XXRemoteVNC*);
		}
		if([addrsplit count] == 2) {
			portNumber += [[addrsplit objectAtIndex:1] intValue];
			if(portNumber < PORT_NUMBER || portNumber > PORT_NUMBER+12) {
				NSLog(@"Not a valid address");
				[self release];
				//[addrsplit release];
				NS_VALUERETURN(nil, XXRemoteVNC*);
			}
		}
		NSLog(@"connecting to host %s on port %0d",
			[[addrsplit objectAtIndex:0] cString], portNumber);

				
		// first do a hostname lookup
	    host = gethostbyname([[addrsplit objectAtIndex:0] cString]);

// XXX: release segfaults. why?
//		[addrsplit release];

	    if (host == NULL)
	    {
	        NSLog(@"Failed to locate host - %s", strerror(errno));
	        [self release];
	        NS_VALUERETURN(nil, XXRemoteVNC*);
	    }
	
	    fd_socket = socket(PF_INET, SOCK_STREAM, 0);
	
	    if (fd_socket == -1)
	    {
	        NSLog(@"Failed to create socket - %s", strerror(errno));
	        [self release];
	        NS_VALUERETURN(nil, XXRemoteVNC*);
	    }
	    addr.sin_family = AF_INET;
	    addr.sin_port = htons(portNumber);
	    memcpy(&addr.sin_addr,host->h_addr_list[0],sizeof(struct in_addr));
	    
		NSLog(@"trying to connect\n");
		
	    if(connect(fd_socket, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
	        NSLog(@"Failed to connect() -  %s", strerror(errno));
	        [self release];
	        NS_VALUERETURN(nil, XXRemoteVNC*);
	    }
	
		NSLog(@"Connected\n");
	
		int protocolVersion;
		char bufProtocolVersion[12];
		[self recv:bufProtocolVersion length:12];
	
		//if(strncmp(bufProtocolVersion, "RFB 003.007\n", 12) == 0) {
		if(0) { // XXX: fix protocol 3.7!
			protocolVersion = 7;
			NSLog(@"using protocol version 3.7");
			[self send:"RFB 003.007\n" length:12];
		} else {
			protocolVersion = 3;
			NSLog(@"using protocol version 3.3");
			[self send:"RFB 003.003\n" length:12];
		} 
		
		//// security negotiation
		uint32_t securityProtocol = 0;
		if(protocolVersion == 3) {
	
			// we're just told which protocol we're going to use
			[self recv:&securityProtocol length:4];
			securityProtocol = ntohl(securityProtocol);
	
		} else {
	
			unsigned char bufInChar;
			[self recv:&bufInChar length:1];
			while(bufInChar--) {
				unsigned char x;
				[self recv:&x length:1];
				
				NSLog(@"Server offers security protocol: %0d", x);
				
				// we prefer 1 (noauth), then 2 (des)
				if(x == 1)
					securityProtocol = 1;
				else if(x == 2 && securityProtocol != 1)
					securityProtocol = 2;
			}
	
		}
			
		if(!securityProtocol) {
			NSLog(@"server didn't offer us an acceptible authentication option");
			[self disconnect];
			[self release];
			NS_VALUERETURN(nil, XXRemoteVNC*);
		}
		
		NSLog(@"security protocol: %0d", securityProtocol);
		if(securityProtocol == 2) { // des
			// we receive a challenge from the server, and encrypt it with a key
			// derived from the password
			unsigned char challenge[16];
			[self recv:challenge length:16];
			
			// vnc has a weird hacked DES which reverses bit ordering in the key
			des_cblock key;
			memset(key, 0, 8);
			int i, bit;
			for(i = 0; i < 8; ++i) {
				unsigned char c = [password cString][i];
				if(!c)
					break;

				for(bit = 0; bit < 8; ++bit)
					if(c & (1<<bit))
						key[i] |= (0x80>>bit);
			}
				
			des_key_schedule sched;
			des_set_key_unchecked(&key, &sched);
			des_cblock *c;
			c = (des_cblock*)(challenge);   des_ecb_encrypt(c, c, &sched, DES_ENCRYPT);
			c = (des_cblock*)(challenge+8); des_ecb_encrypt(c, c, &sched, DES_ENCRYPT);

			[self send:challenge length:16];
		
			//get server response
			uint32_t resp;
			[self recv:&resp length:4];
			resp = ntohl(resp);
			if(resp != 0) {
				NSLog(@"server says auth failed");
				[self disconnect];
				[self release];
				NS_VALUERETURN(nil, XXRemoteVNC*);
			}
		}
	
		// will we allow the display to be shared?
		// i can't think of a reason not to
		{
			unsigned char x = 1;
			[self send:&x length:1];
		}
	
		// read framebuffer width and height
		{
			uint16_t x[2];
			[self recv:x length:4];
			displaySize.size.width  = (float)ntohs(x[0]);
			displaySize.size.height = (float)ntohs(x[1]);
			displaySize.origin.x = 0.0;
			displaySize.origin.y = 0.0;
	
			NSLog(@"remote dimensions: %0d x %0d", 
				(int)displaySize.size.width,
				(int)displaySize.size.height);
	
		}
	
		// pixel format, which we just don't care about
		{
			unsigned char x[16];
			[self recv:x length:16];
		}
		
		// name of the server
		{
			uint32_t len;
			[self recv:&len length:4];
			len = ntohl(len);
	
			char *servname = malloc(len + 1);
			[self recv:servname length:len];
			servname[len] = '\0';

			NSLog(@"server name: %s", servname);

			free(servname);
		}
	
		// non blocking socket
		if(fcntl(fd_socket, F_SETFL, O_NONBLOCK) == -1) {
			NSLog(@"couldn't establish non-blocking socket");
			[self disconnect];
			[self release];
			NS_VALUERETURN(nil, XXRemoteVNC*);
		}
	
		// disable the nagle algorithm
		int nd = 1;
		if(setsockopt(fd_socket, IPPROTO_TCP, TCP_NODELAY, &nd, sizeof(int))
			== -1) 
		{
			NSLog(@"warning - couldn't set TCP_NODELAY. slowness!!");
		}
	
		// we want to hear about incoming data, so wrap in an NSFileHandle
		// and register for notifications
		sock = [[NSFileHandle alloc] initWithFileDescriptor: fd_socket
		                                     closeOnDealloc: NO];

		[[NSNotificationCenter defaultCenter]
				addObserver: self
				selector: @selector(suck)
				name: NSFileHandleDataAvailableNotification
				object: sock];

		[sock waitForDataInBackgroundAndNotify];

		shifted_left = FALSE;
		shifted_right = FALSE;
		alted_right = FALSE;
	NS_HANDLER
		[self disconnect];
		[self release];
		//self = nil;
	NS_ENDHANDLER

    return self;
}


- (NSRect)displaySize
{
    return displaySize;
}


/***************************
 * send messages
 */
- (void)sendMouseMessage
{
	unsigned char msg[6];
	msg[0] = 5;
	msg[1] = mouseButtons;
	msg[2] = (int)mousePosition.x / 256;
	msg[3] = (int)mousePosition.x & 0xFF;
	msg[4] = (int)mousePosition.y / 256;
	msg[5] = (int)mousePosition.y & 0xFF;

	[self send:msg length:6];
}

- (void)sendKeyPress: (int)keycode
         inDirection: (enum XXDIRECTION)direction
{

	const char *dirstr = "other";
	switch(direction) {
		case XD_UP:   dirstr = "  up"; break;
		case XD_DOWN: dirstr = "down"; break;
	}
	NSLog(@"%s: %0d", dirstr, keycode);

	if(keycode < 0 || keycode > 127 || keymap[keycode] == -1)
		return;

	uint32_t keyNetwork;
        
        if (keycode == 56)
            shifted_left = !shifted_left;
        if (keycode == 60)
            shifted_right = !shifted_right;
		if (keycode == 61)
			alted_right = !alted_right;
        
        if (shifted_left || shifted_right)
            keyNetwork = htonl(keymap_shifted[keycode]);
		else if (alted_right)
			keyNetwork = htonl(keymap_alted[keycode]);
        else
            keyNetwork = htonl(keymap[keycode]);
	
	unsigned char msg[8];
	msg[0] = 4;
	msg[1] = (direction == XD_DOWN) ? 1 : 0;
	msg[2] = msg[3] = 0;
	memcpy(msg+4, &keyNetwork, 4);
	
	[self send:msg length:8];
}


/***************************
 * alter mouse state and send it up to the server
 */

- (void)moveCursorRelative: (NSPoint)position
{
	mousePosition.x += position.x;
	mousePosition.y += position.y;
	[self sendMouseMessage];
}


- (void)moveCursorAbsolute: (NSPoint)position
{
	mousePosition = position;
	[self sendMouseMessage];
}


- (void)sendMousePress: (int)button
           inDirection: (enum XXDIRECTION)direction
{
	// we want a bitmask, not a number
	button = 1 << (button - 1);

	if(direction == XD_DOWN)
		mouseButtons |= button;
	else
		mouseButtons &= ~button;

	[self sendMouseMessage];
}


- (void)pasteToRemote: (char*)data
{
	NSLog(@"paste: %s", data);

	uint32_t len = strlen(data);
	unsigned char *msg = malloc(8 + len);

	msg[0] = 6; msg[1] = 0; msg[2] = 0; msg[3] = 0;

	uint32_t x = htonl(len); memcpy(msg + 4, &x, 4);

	memcpy(msg + 8, data, len);
	
	[self send:msg length:(8 + len)];
	free(msg);
}


- (void)copyFromRemote
{
}


- (void)sendControlAltDelete
{
	unsigned char msg[8];
	  
	// constants pulled from chicken of the vnc
	const uint32_t control = htonl(0xffe3);
	const uint32_t alt = htonl(0xffe9);
	const uint32_t del = htonl(0xffff);
	
	memset(msg, 0x00, sizeof(msg) );
	msg[0] = 4; // RFB Key event
	msg[1] = 1; // keydown
	memcpy( msg+4, &control, 4 );
	[self send:msg length:8];
	memcpy( msg+4, &alt, 4 );
	[self send:msg length:8];
	memcpy( msg+4, &del, 4 );
	[self send:msg length:8];
	msg[1] = 0; // keyup
	memcpy( msg+4, &del, 4 );
	[self send:msg length:8];
	memcpy( msg+4, &alt, 4 );
	[self send:msg length:8];
	memcpy( msg+4, &control, 4);
	[self send:msg length:8];
}


- (void)disconnect
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
	
	if(sock != nil)
		[sock release];
	sock = nil;

    if(fd_socket != -1)
		close(fd_socket);
    fd_socket = -1;
}


- (void)dealloc
{
    [self disconnect];
    [super dealloc];
}


@end

