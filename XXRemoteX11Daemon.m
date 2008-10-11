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

#import "XXRemoteX11Daemon.h"
#import <unistd.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <errno.h>
#import <netdb.h>
#import <strings.h>

#include <openssl/ssl.h>

#define PORT_NUMBER 3376

struct initinfo
{
    uint32_t length;
    uint32_t major_version;  // Changed when interface becomes incompatible
    uint32_t minor_version;  // Changed each revision of daemon
    uint32_t width;
    uint32_t height;
};


// osx2x -> daemon request opcodes
#define GIVEINFO      0x0
#define RELATIVE_MOVE 0x1
#define ABSOLUTE_MOVE 0x2
#define BUTTON_EVENT  0x3
#define KEY_EVENT     0x4
#define CLOSE_CON     0x5

@implementation XXRemoteX11Daemon

- initWithHostName: (NSString*)hostname
{
    if (self = [super init])
    {
        int rv, i;
        struct sockaddr_in addr;
        struct hostent *host;
        struct initinfo data;

        // first do a hostname lookup
        host = gethostbyname([hostname cString]);

        if (host == NULL)
        {
            NSLog(@"Failed to locate host - %s", strerror(errno));
            [self release];
            return nil;
        }

        // Init the SSL connection
        SSLeay_add_ssl_algorithms();
        meth = SSLv2_client_method();
        SSL_load_error_strings();
        ctx = SSL_CTX_new (meth);         
        
        fd_socket = socket(PF_INET, SOCK_STREAM, 0);

        if (fd_socket == -1)
        {
            NSLog(@"Failed to create socket - %s", strerror(errno));
            [self release];
            return nil;
        }

        addr.sin_family = AF_INET;
        addr.sin_port = htons(PORT_NUMBER);
//        addr.sin_len = 4;
        memcpy(&addr.sin_addr,host->h_addr_list[0],sizeof(struct in_addr));
        
        rv = connect(fd_socket, (struct sockaddr*)&addr, sizeof(addr));

        if (rv == -1)
        {
            close(fd_socket);
            NSLog(@"Failed to create socket - %s", strerror(errno));
            [self release];
            return nil;
        }


        ssl = SSL_new (ctx);

        if (ssl == NULL)
        {
            [self disconnect];
            NSLog(@"Failed to create SSL object - %s", strerror(errno));
            [self release];
            return nil;
        }
        
        SSL_set_fd (ssl, fd_socket);
        /*err =*/ SSL_connect (ssl);                     


        /* Get the cipher - opt */

        printf ("SSL connection using %s\n", SSL_get_cipher (ssl));

        rv = 0;
        for (i = 0; i < 10; i++)
        {
            NSLog(@"hmm %d", rv);
            if ((rv = SSL_read(ssl, &data, sizeof(data))) > 0)
                break;

            if (rv < 0)
            {
                [self disconnect];
                NSLog(@"Failed to get correct init info (%d != %d)\n", rv, sizeof(data));
                [self release];
                return nil;
            }
        }

        NSLog(@"gah");
        
        // The client should have sent us some information about itself now
        if (rv != sizeof(data))
        {
            [self disconnect];
            NSLog(@"Failed to get correct init info (%d != %d)\n", rv, sizeof(data));
            [self release];
            return nil;
        }


        NSLog(@"blur");
        
        displaySize.origin.x = 0.0;
        displaySize.origin.y = 0.0;
        displaySize.size.width = (float)ntohl(data.width);
        displaySize.size.height = (float)ntohl(data.height);
    }

    return self;
}


- (NSRect)displaySize
{
    return displaySize;
}


- (void)moveCursorRelative: (NSPoint)position
{
    uint32_t data[3];

    data[0] = htonl(RELATIVE_MOVE);
    data[1] = htonl((int)position.x);
    data[2] = htonl((int)position.y);

    SSL_write(ssl, &data, sizeof(uint32_t) * 3);
}


- (void)moveCursorAbsolute: (NSPoint)position
{
    uint32_t data[3];

    data[0] = htonl(ABSOLUTE_MOVE);
    data[1] = htonl((int)position.x);
    data[2] = htonl((int)position.y);

    SSL_write(ssl, &data, sizeof(uint32_t) * 3);
}


- (void)sendKeyPress: (int)keycode
         inDirection: (enum XXDIRECTION)direction
{
    uint32_t data[3];
    
    if ((keycode >= 0) && (keycode < 128))
    {
        data[0] = htonl(KEY_EVENT);
        data[1] = htonl(keycode);
        data[2] = htonl( (direction == XD_DOWN) ? TRUE : FALSE );

        SSL_write(ssl, &data, sizeof(uint32_t) * 3);
    }
}


- (void)sendMousePress: (int)button
           inDirection: (enum XXDIRECTION)direction
{
    uint32_t data[3];

    data[0] = htonl(BUTTON_EVENT);
    data[1] = htonl(button);
    data[2] = htonl( (direction == XD_DOWN) ? TRUE : FALSE );

    SSL_write(ssl, &data, sizeof(uint32_t) * 3);
}


- (void)pasteToRemote: (char*)data
{
}


- (void)copyFromRemote
{
}


- (void)disconnect
{
    uint32_t data = CLOSE_CON;
    
    SSL_write(ssl, &data, sizeof(uint32_t));

    close(fd_socket);
    fd_socket = -1;
    if (ssl != NULL)
        SSL_free (ssl);
    if (ctx != NULL)
        SSL_CTX_free(ctx);
}


- (void)dealloc
{
    if (fd_socket != -1)
        [self disconnect];

    [super dealloc];
}



@end
