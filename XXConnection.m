//
//  XXConnection.m
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

#import "XXConnection.h"
#import "XXRemoteXWindows.h"
#import "XXRemoteVNC.h"
#import "XXArrowView.h"
#import "XXArrowWindow.h"

#define NONE NSLocalizedStringFromTable(@"None", @"osx2x", "Connection direction")
#define EAST NSLocalizedStringFromTable(@"East", @"osx2x", "Connection direction")
#define WEST NSLocalizedStringFromTable(@"West", @"osx2x", "Connection direction")
#define NORTH NSLocalizedStringFromTable(@"North", @"osx2x", "Connection direction")
#define SOUTH NSLocalizedStringFromTable(@"South", @"osx2x", "Connection direction")


static const NSString* connectionNames[3] = {@"X11", @"VNC", @"Daemon"};
static NSString* positionNames[5];// = {@"None", @"East", @"West", @"North", @"South"};

@implementation XXConnection

/*------------------------------------------------------------------------------
 * 
 */
-initWithHost: (NSString*)hname
 withPosition: (XXWindowPos)pos
 withUsername: (NSString*) username
 withPassword: (NSString*) password
     withType: (XXConnectionType)type
forController: (XXController*)cont
{
    if ((self = [super init]) != nil)
    {
        hostname = [[NSString alloc] initWithString: hname];
        position = pos;
        connectionType = type;
        controller = cont;

        // Should depend on type
        switch (type)
        {
        case 0:
            remoteControl = [[XXRemoteXWindows alloc] initWithHostName: hostname];
            break;
        case 1:
            remoteControl = [[XXRemoteVNC alloc] initWithHostName: hostname
                withPassword: password];
            break;
        default:
            remoteControl = nil;
        }
            
        if (remoteControl == nil)
        {
            [hostname release];
            hostname = nil;
            [self release];
            return nil;
        }

        if (pos != XXWindowNone)
        {
            [self buildCaptureWindow: pos];
            [self buildArrowWindow: pos];
        }
        else
        {
            controlWindow = nil;
            controlView = nil;
            arrowWin = nil;
            arrowView = nil;
        }

        positionNames[0] = NONE;
        positionNames[1] = EAST;
        positionNames[2] = WEST;
        positionNames[3] = NORTH;
        positionNames[4] = SOUTH;
    }

    return self;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)dealloc
{
    if (remoteControl != nil)
        [self disconnect];

    if (hostname != nil)
        [hostname release];
    
    if (arrowWin != nil)
        [arrowWin release];
	
    [super dealloc];
}


/*------------------------------------------------------------------------------
 * disconnect - Ideally this would be just done when we destroy the object to
 *              allow the connection to be an invarient on the object, but we
 *              also need to ensure that the connection is torn down when we say
 *              so, which we can't guarentee with a garbage collector.
 */
- (void)disconnect
{
    if (controlWindow != nil)
    {
        [controlWindow close];
        controlWindow = nil;
        controlView = nil;
    }
    
    [remoteControl disconnect];
    [remoteControl release];
    remoteControl = nil;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)buildArrowWindow: (XXWindowPos)pos
{
    NSRect rect;
    
    // buildCaptureWindow has already found out what screen we're on in
    // the CGRect screenSize.
    rect.size.width = 150.0;
    rect.size.height = 150.0;
	
    switch (pos)
    {
        case XXWindowEast:
            rect.origin.x = screenSize.origin.x + (screenSize.size.width - (150.0 + 100.0));
            rect.origin.y = screenSize.origin.y + ((screenSize.size.height - 150.0) / 2.0);
            break;
        case XXWindowWest:
            rect.origin.x = screenSize.origin.x + 100.0;
            rect.origin.y = screenSize.origin.y + ((screenSize.size.height - 150.0) / 2.0);
            break;
        case XXWindowNorth:
            rect.origin.x = screenSize.origin.x + ((screenSize.size.width - 150.0) / 2.0);
            rect.origin.y = screenSize.origin.y + (screenSize.size.height - (150.0 + 100.0));
            break;
        case XXWindowSouth:
            rect.origin.x = screenSize.origin.x + ((screenSize.size.width - 150.0) / 2);
            rect.origin.y = screenSize.origin.y + 100.0;
            break;
        default:
            // can't get here
            rect.origin.x = rect.origin.y = 0.0;
    }
    
    arrowWin = [[XXArrowWindow alloc] initWithContentRect: rect
                                           styleMask: NSBorderlessWindowMask
                                             backing: NSBackingStoreBuffered
                                               defer: NO];
    [arrowWin setBackgroundColor: [NSColor clearColor]];
    [arrowWin setLevel: NSStatusWindowLevel];
    [arrowWin setAlphaValue: 0.3];
    [arrowWin setOpaque: NO];
    [arrowWin setHasShadow: NO];
    
    arrowView = [[XXArrowView alloc] initWithFrame: rect
                                     withDirection: pos];
	
    [arrowWin setContentView: arrowView];
	[arrowWin makeFirstResponder: arrowView];
	[arrowWin setReleasedWhenClosed: NO];
}


/*------------------------------------------------------------------------------
 * buildCaptureWindow - Builds a window for doing mouse capture
 */
- (void)buildCaptureWindow: (XXWindowPos)pos
{
    NSRect r;
    CGDirectDisplayID displays[5];
    CGDisplayCount dcount;
    int screen = -1;

    // First job is to get the metrics of the main screen
    CGGetActiveDisplayList((CGDisplayCount)5, displays, &dcount);

    switch (pos)
    {
        case XXWindowEast:
        {
            int i;
            int max = -1;

            // Find leftmost screen
            for (i = 0; i < dcount; i++)
            {
                screenSize = CGDisplayBounds(displays[i]);
                if (screenSize.origin.x > max)
                {
                    screen = i;
                    max = screenSize.origin.x;
                }
            }
        }
            break;
        case XXWindowWest:
        {
            int i;
            int max = 1;

            // Find leftmost screen
            for (i = 0; i < dcount; i++)
            {
                screenSize = CGDisplayBounds(displays[i]);
                if (screenSize.origin.x < max)
                {
                    screen = i;
                    max = screenSize.origin.x;
                }
            }
        }
            break;
        case XXWindowNorth:
        {
            int i;
            int max = -1;

            // Find topmost screen
            for (i = 0; i < dcount; i++)
            {
                screenSize = CGDisplayBounds(displays[i]);
                if (screenSize.origin.y > max)
                {
                    screen = i;
                    max = screenSize.origin.y;
                }
            }
        }
            break;
        case XXWindowSouth:
        {
            int i;
            int max = 1;

            // Find bottommost screen
            for (i = 0; i < dcount; i++)
            {
                screenSize = CGDisplayBounds(displays[i]);
                if (screenSize.origin.y < max)
                {
                    screen = i;
                    max = screenSize.origin.y;
                }
            }
        }
            break;
        case XXWindowNone:
            // should never get here...
            break;
    }

    screenSize = CGDisplayBounds(displays[screen]);

    //[xxView setCaptureScreen: screenSize];

    // Work out the frame for the new window
    if ((pos == XXWindowEast) || (pos == XXWindowWest))
    {
        r.size.width = 1.0;
        r.size.height = screenSize.size.height;
    }
    else
    {
        r.size.height = 1.0;
        r.size.width = screenSize.size.width;
    }


    if ((pos == XXWindowWest) || (pos == XXWindowSouth))
    {
        r.origin.x = 0.0;
        r.origin.y = 0.0;
    }
    else if (pos == XXWindowEast)
    {
        r.origin.x = screenSize.size.width - 1;
        r.origin.y = 0.0;
    }
    else
    {
        // pos == XXWindowNorth
        r.origin.x = 0.0;
        r.origin.y = screenSize.size.height - 1;
    }

    r.origin.x += screenSize.origin.x;
    r.origin.y -= screenSize.origin.y;

    controlWindow = [[XXTransparentWin alloc] initWithContentRect: r
                                                styleMask: NSBorderlessWindowMask
                                                  backing: NSBackingStoreRetained
                                                    defer: NO];

    r.origin.y = 0.0;
    r.origin.x = 0.0;
    controlView = [[NSView alloc] initWithFrame: r];

    [controlWindow setContentView: controlView];
    [controlWindow makeFirstResponder: controlView];
    [controlWindow makeKeyAndOrderFront: nil];
    //[win orderFrontRegardless];

    // make this window invisiable
    [controlWindow setBackgroundColor: [NSColor clearColor]];
    [controlWindow setLevel: NSStatusWindowLevel];
    [controlWindow setAlphaValue: 1.0];
    [controlWindow setOpaque: NO];
    [controlWindow setHasShadow: NO];

    r.origin.x = 0.0;
    [controlView addTrackingRect: r
                           owner: self
                        userData: NULL
                    assumeInside: NO];
}


/*------------------------------------------------------------------------------
 *
 */
- (void)mouseEntered: (NSEvent*) theEvent
{
    [controller setActiveController: self];
    [controlWindow orderFrontRegardless];
}

- (void)mouseExited: (NSEvent*) theEvent
{
    // Not used, but needed to allow the object to respond to rect entered events
}


/*------------------------------------------------------------------------------
 *
 */
-(NSString*)getHostName
{
    return hostname;
}


/*------------------------------------------------------------------------------
 *
 */
-(NSString*)getPositionName
{
    return positionNames[position];
}


/*------------------------------------------------------------------------------
 *
 */
-(NSString*)getConnectionName
{
    return (NSString*)connectionNames[connectionType];
}


/*------------------------------------------------------------------------------
 *
 */
-(id)getRemoteController
{
    return remoteControl;
}


/*------------------------------------------------------------------------------
 *
 */
-(XXWindowPos)getPosition
{
    return position;
}


/*------------------------------------------------------------------------------
 *
 */
-(CGRect)getScreenSize
{
    return screenSize;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)setArrowVisible: (BOOL)vis
{
	if (arrowWin == nil)
		return;
	
	if (vis)
	{
		[arrowWin makeKeyAndOrderFront: nil];    
		//NSLog(@"Showing arrow\n");
	}
	else
	{
		[arrowWin close];
		//NSLog(@"Hiding arrow\n");
	}
}

-(id)getArrowView
{
	return arrowView;
}


@end
