//
// XXView.m
// osx2x
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

#import "XXView.h"
#import "XXAbstractRemote.h"
#import <Carbon/Carbon.h>
#import "XXController.h"

@implementation XXView

/*------------------------------------------------------------------------------
 * initWithFrame - constructor
 */
- (id)initWithFrame:(NSRect)rect
{
    if (self = [super initWithFrame:rect])
    {
        locked = FALSE;
        memset(keyState, 0, 128);
        controller = nil;
        remote = nil;
		
		[self updatePrefs];
    }

    return self;
}

- (void)updatePrefs
{
	NSUserDefaults *defaults;

    defaults = [NSUserDefaults standardUserDefaults];
	
	mouseEmulation = [defaults boolForKey: OXEmulateButtonsKey];
	rightModifier = [defaults integerForKey: OXRightModifierKey];
	middleModifier = [defaults integerForKey: OXMiddleModifierKey];
	disableScrolling = [defaults boolForKey: OXDisableScrollKey];
}

- (void)setController: (XXController*)cont
{
    controller = cont;
}

- (void)setRemote: (id)r
{
    remote = r;

    screenSize = [remote displaySize];
}

// Added for wacom support
- (BOOL)mouseDownCanMoveWindow
{
    return NO;
}


- (void)setLockLocation: (NSPoint)loc
{
    lockLocation = loc;
}

- (void)setCaptureScreen: (CGRect)s
{
    captScreen = s;
}

/*------------------------------------------------------------------------------
 *
 */
- (void)toggleLockWithPosition: (XXWindowPos)pos;
{
    if (remote == nil)
        return;
    
    locked = !locked;
    
    if (locked)
    {
        //CGPoint cp;
        NSPoint temp;
        NSScreen *disp;
        NSDictionary *devInfo;
        NSValue *val;
        NSSize screen;
        NSRect bounds = [self bounds];

        // Is this going to be a relative thing or not?
        winPos = pos;
        if (pos == XXWindowNone)
        {
            isRelative = YES;
        }
        else
        {
            isRelative = NO;

            if ((pos == XXWindowEast) || (pos == XXWindowWest))
            {
                cursorPos.x = pos == XXWindowWest ? screenSize.size.width : 0;
                cursorPos.y = screenSize.size.height - lockLocation.y;            }
            else
            {
                cursorPos.x = lockLocation.x;
                cursorPos.y = pos == XXWindowNorth ? screenSize.size.height : 0;
            }
        }
        
        [[self window] makeFirstResponder: self];
        
        [[self window] setAcceptsMouseMovedEvents: YES];
        CGAssociateMouseAndMouseCursorPosition(FALSE);
        [NSApp activateIgnoringOtherApps: YES];
        [NSCursor hide];

        // Work out the position we want to put the cursor in (the top left of the view)
        oldMouse.x = (bounds.size.width / 2) + bounds.origin.x;
        oldMouse.y = (bounds.size.height / 2) + bounds.origin.y;
        temp = [[self window] convertBaseToScreen: oldMouse];

        // Make a note of the current cursor position so we can restore it
        oldMouse = [NSEvent mouseLocation];

        // Find out the screen size - I do this dynamically incase we moved displays
        disp = [NSScreen mainScreen];
        devInfo = [disp deviceDescription];
        val = [devInfo objectForKey: NSDeviceSize];
        screen = [val sizeValue];

        lockPos.x = temp.x;
        lockPos.y = screen.height - temp.y;
        CGWarpMouseCursorPosition(lockPos);

        // if we don't ignore the first mouse event after locking we get that
        // warp we just issued
        justLocked = TRUE;
		
		
		// Has the user got any keys held down?
		[self pressAllFlags];
    }
    else
    {
        CGPoint cp;
        NSSize screen;
        NSValue *val;
        NSScreen *disp;
        NSDictionary *devInfo;
        
		[self unpressAllFlags];
		
        [[self window] setAcceptsMouseMovedEvents: NO];

        // Find out the screen size - I do this dynamically incase we moved displays
        disp = [NSScreen mainScreen];
        devInfo = [disp deviceDescription];
        val = [devInfo objectForKey: NSDeviceSize];
        screen = [val sizeValue];

        // Put cursor back so it's not in the trap window
        if (winPos == XXWindowEast)
        {            
            cp.x = captScreen.size.width - 3;
            cp.x += captScreen.origin.x;
            cp.y = screen.height - (screenSize.size.height - cursorPos.y);
            if (cp.y > screen.height)
                cp.y = screen.height - 1.0;
        }
        else if (winPos == XXWindowWest)
        {
            cp.x = 3;
            cp.x += captScreen.origin.x;
            cp.y = screen.height - (screenSize.size.height - cursorPos.y);
            if (cp.y > screen.height)
                cp.y = screen.height - 1.0;
        }
        else if (pos == XXWindowSouth)
        {
            cp.y = 3;
            cp.y += captScreen.origin.y;

            cp.x = cursorPos.x;
            if (cp.x > screen.width)
                cp.x = screen.width - 1.0;
        }
        else if (pos == XXWindowNorth)
        {
            cp.y = captScreen.size.height - 3;
            cp.y += captScreen.origin.y;

            cp.x = cursorPos.x;
            if (cp.x > screen.width)
                cp.x = screen.width - 1.0;
        }
        else
        {
            cp.x = oldMouse.x;
            cp.y = screen.height - oldMouse.y;
        }
        
        //NSLog(@"Set cursor to (%f, %f)\n", cp.x, cp.y);
        CGWarpMouseCursorPosition(cp);
        
        CGAssociateMouseAndMouseCursorPosition(TRUE);
        [NSCursor unhide];
		
    }
}


/*------------------------------------------------------------------------------
 *
 */
- (BOOL)acceptsFirstResponder
{
    return YES;
}


/*------------------------------------------------------------------------------
 *
 */
- (BOOL)resignsFirstResponder
{
    [self setNeedsDisplay: YES];
    return YES;
}

- (void)criticalDisconnect
{
    memset(keyState, 0, 128);
    [controller criticalDisconnect];
}


/*------------------------------------------------------------------------------
 *
 */
- (BOOL)becomeFirstResponder
{
    [self setNeedsDisplay: YES];
    return YES;
}


#include <X11/keysym.h>

/*------------------------------------------------------------------------------
 * keyDown - record a key down event.
 */
- (void)keyDown:(NSEvent *)theEvent
{
    int keycode = [theEvent keyCode];

    //NSLog(@"key = %d %@\n", keycode, [theEvent characters]);

    if (remote == nil)
        return;

    if (locked == FALSE)
        return;
    
    NS_DURING
        [remote sendKeyPress: keycode
                 inDirection: XD_DOWN];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 * keyUp - record a key release event.
 */
- (void)keyUp:(NSEvent *)theEvent
{
    int keycode = [theEvent keyCode];

    if (remote == nil)
        return;

    if (locked == FALSE)
        return;
    
    NS_DURING
        [remote sendKeyPress: keycode
                 inDirection: XD_UP];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 * flagsChanged - this is called if a modifier key is pressed. Most keys follow
 *                the usual even for up and event for down, except for caps lock
 *                which is sticky.
 */
- (void)flagsChanged:(NSEvent *)theEvent
{
    int c = [theEvent keyCode];

    //NSLog(@"The flag is %d\n", c);

    if (locked == FALSE)
        return;

    if (remote == nil)
        return;
    
    keyState[c] = (keyState[c] == 0) ? 1 : 0;

    // XCloseDisplay throws a wobbly if we ever try to convert and send
    // the apple key
    if (c == 55)
        return;

    NS_DURING
        [remote sendKeyPress: c
                 inDirection: keyState[c] == 1 ? XD_DOWN : XD_UP];

        if ((c == 57) || (c == 127))
        {
            [remote sendKeyPress: c
                     inDirection: XD_UP];
            keyState[c] = 0;
        }
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER

}



/*------------------------------------------------------------------------------
 * pressAllFlags - notes what modifiers are on when the user moves to the
 *                 remote machine, and virtually "presses" those keys on the 
 *                 remote side.
 *
 *				   GetCurrentKeyModifiers only returns modifier info as if the
 *				   the left key had been pressed, regardless of which has been
 *                 pressed (as does GetKeys). This leaves us with a dilemma, as
 *                 they key release event won't match. I smell a hack...
 */
- (void)pressAllFlags
{
	UInt32 keys;
	KeyMap allKeys;
	
	bzero(hackedKeyState, 128);
	
	keys = GetCurrentKeyModifiers();
	GetKeys(allKeys);
	//NSLog(@"modifiers = 0x%08x allkeys=0x%08x%08x%08x%08x", keys, allKeys[0], allKeys[1], allKeys[2], allKeys[3]);
	
	if (keys & shiftKey)
	{
	}
}


/*------------------------------------------------------------------------------
 * unpressAllFlags - called when the mouse moves back to the macosx side, 
 *					sending a keyup event for any depressed keys.
 */
- (void)unpressAllFlags
{
	int i;
	
	NS_DURING
		for (i = 0; i< 128; i++)
		{
			if (keyState[i] == 1)
			{
				[remote sendKeyPress: i
						 inDirection: XD_UP];
				keyState[i] = 0;
			}
		}
	NS_HANDLER
		[self criticalDisconnect];
	NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 * mouseMoved - If this gets called then we are tracking mouse movement (else
 *              mouse movement events are not monitored due to expense).
 */
- (void)mouseMoved:(NSEvent *)theEvent
{
    CGMouseDelta x, y;
    
    // Moved here to remove the coordinates from teh queue, required under Panther
    CGGetLastMouseDelta(&x, &y);
    
    if (locked && !justLocked)
    {
        NSPoint p;
        
        CGWarpMouseCursorPosition(lockPos);

        //NSLog(@"Mouse delta = (%d, %d)\n", x, y);
                
        if (isRelative)
        {
            NS_DURING
                p.x = x;
                p.y = y;                
                [remote moveCursorRelative: p];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
        else
        {
            cursorPos.x += x;
            cursorPos.y += y;

            //NSLog(@"cur pos = (%f, %f)  winPos = %d\n", cursorPos.x, cursorPos.y, winPos);
			//NSLog(@"scr siz = (%f, %f)\n", screenSize.size.width, screenSize.size.height);
            
            if (winPos == XXWindowWest)
            {
                if (cursorPos.x > screenSize.size.width)
                {
                    // the cursor is off the
                    //[NSApp hide: nil];
                    [controller toggleLock: nil];
                    [controller promoteFrontApp];
					//NSLog(@"blah\n");
                }
                if (cursorPos.x < 0)
                    cursorPos.x = 0;

                // Limit the height
                if (cursorPos.y < 0)
                    cursorPos.y = 0;
                if (cursorPos.y > screenSize.size.height)
                    cursorPos.y = screenSize.size.height;
                
            }
            else if (winPos == XXWindowEast)
            {
                if (cursorPos.x < 0)
                {
                    // the cursor is off the
                    //[NSApp hide: nil];
                    //[NSApp deactivate];
                    [controller toggleLock: nil];
                    [controller promoteFrontApp];
                }
                if (cursorPos.x > screenSize.size.width)
                    cursorPos.x = screenSize.size.width;

                // Limit the height
                if (cursorPos.y < 0)
                    cursorPos.y = 0;
                if (cursorPos.y > screenSize.size.height)
                    cursorPos.y = screenSize.size.height;   
            }
            else if (winPos == XXWindowSouth)
            {
                if (cursorPos.y < 0)
                {
                    [controller toggleLock: nil];
                    [controller promoteFrontApp];
                }
                if (cursorPos.y > screenSize.size.height)
                    cursorPos.y = screenSize.size.height;

                if (cursorPos.x < 0)
                    cursorPos.x = 0;
                if (cursorPos.x > screenSize.size.width)
                    cursorPos.x = screenSize.size.width;            }
            else if (winPos == XXWindowNorth)
            {
                if (cursorPos.y > screenSize.size.height)
                {
                    [controller toggleLock: nil];
                    [controller promoteFrontApp];
                }
                if (cursorPos.y < 0)
                    cursorPos.y = 0;

                if (cursorPos.x < 0)
                    cursorPos.x = 0;
                if (cursorPos.x > screenSize.size.width)
                    cursorPos.x = screenSize.size.width;
            }
            NS_DURING
                [remote moveCursorAbsolute: cursorPos];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
    }
    justLocked = FALSE;
}


/*------------------------------------------------------------------------------
 * mouseDragged - essentially the same as a mouse move in ArcEm's eyes
 */
- (void)mouseDragged: (NSEvent *)theEvent
{
    CGMouseDelta x, y;
    NSPoint p;

    if (locked && !justLocked)
    {
        CGGetLastMouseDelta(&x, &y);
        CGWarpMouseCursorPosition(lockPos);

        if (isRelative)
        {
            NS_DURING
                p.x = x;
                p.y = y;
                [remote moveCursorRelative: p];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
        else
        {
            cursorPos.x += x;
            cursorPos.y += y;

            //NSLog(@"cur pos = (%d, %d)\n", cursorPos.width, cursorPos.height);

            // Limit the height
            if (cursorPos.y < 0)
                cursorPos.y = 0;
            if (cursorPos.y >= screenSize.size.height)
                cursorPos.y = screenSize.size.height - 1;
            if (cursorPos.x < 0)
                cursorPos.x = 0;
            if (cursorPos.x >= screenSize.size.width)
                cursorPos.x = screenSize.size.width - 1;

            NS_DURING
                [remote moveCursorAbsolute: cursorPos];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
            
        }
    }
    justLocked = FALSE;
}



/*------------------------------------------------------------------------------
* mouseDragged - essentially the same as a mouse move in ArcEm's eyes
*/
- (void)rightMouseDragged: (NSEvent *)theEvent
{
    CGMouseDelta x, y;
    NSPoint p;

    if (locked && !justLocked)
    {
        CGGetLastMouseDelta(&x, &y);
        CGWarpMouseCursorPosition(lockPos);


        if (isRelative)
        {
            NS_DURING
                p.x = x;
                p.y = y;
                [remote moveCursorRelative: p];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
        else
        {
            cursorPos.x += x;
            cursorPos.y += y;

            //NSLog(@"cur pos = (%d, %d)\n", cursorPos.width, cursorPos.height);

            if (cursorPos.y < 0)
                cursorPos.y = 0;
            if (cursorPos.y >= screenSize.size.height)
                cursorPos.y = screenSize.size.height - 1;
            if (cursorPos.x < 0)
                cursorPos.x = 0;
            if (cursorPos.x >= screenSize.size.width)
                cursorPos.x = screenSize.size.width - 1;
            
            NS_DURING
                [remote moveCursorAbsolute: cursorPos];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
    }
    justLocked = FALSE;
}




/*------------------------------------------------------------------------------
* mouseDragged - essentially the same as a mouse move in ArcEm's eyes
*/
- (void)otherMouseDragged: (NSEvent *)theEvent
{
    CGMouseDelta x, y;
    NSPoint p;

    if (locked && !justLocked)
    {
        CGGetLastMouseDelta(&x, &y);
        CGWarpMouseCursorPosition(lockPos);

        if (isRelative)
        {
            NS_DURING
                p.x = x;
                p.y = y;
                [remote moveCursorRelative: p];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }
        else
        {
            cursorPos.x += x;
            cursorPos.y += y;

            //NSLog(@"cur pos = (%d, %d)\n", cursorPos.width, cursorPos.height);

            if (cursorPos.y < 0)
                cursorPos.y = 0;
            if (cursorPos.y >= screenSize.size.height)
                cursorPos.y = screenSize.size.height - 1;
            if (cursorPos.x < 0)
                cursorPos.x = 0;
            if (cursorPos.x >= screenSize.size.width)
                cursorPos.x = screenSize.size.width - 1;

            NS_DURING
                [remote moveCursorAbsolute: cursorPos];
            NS_HANDLER
                [self criticalDisconnect];
            NS_ENDHANDLER
        }

    }
    justLocked = FALSE;}


/*------------------------------------------------------------------------------
 * 
 */
- (void)mouseDown: (NSEvent *)theEvent
{
	int button;
	
    if (remote == nil)
        return;

    if (!locked)
        return;

	if (mouseEmulation)
	{
        if (keyState[rightModifier])
            button = 0x03;
        else if (keyState[middleModifier])
            button = 0x02;
        else
            button = 0x01;
	}
	else
		button = 0x01;
	
    NS_DURING
        [remote sendMousePress: button
                   inDirection: XD_DOWN];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 *
 */
- (void)mouseUp: (NSEvent *)theEvent
{
	int button;
	
    if (remote == nil)
        return;

    if (!locked)
        return;

	if (mouseEmulation)
	{
        if (keyState[rightModifier])
            button = 0x03;
        else if (keyState[middleModifier])
            button = 0x02;
        else
            button = 0x01;
	}
	else
		button = 0x01;
	
    NS_DURING
        [remote sendMousePress: button
                   inDirection: XD_UP];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER}


/*------------------------------------------------------------------------------
 *
 */
- (void)rightMouseDown: (NSEvent *)theEvent
{
    if (remote == nil)
        return;

    if (!locked)
        return;

    NS_DURING
        [remote sendMousePress: 3
                   inDirection: XD_DOWN];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 *
 */
- (void)rightMouseUp: (NSEvent *)theEvent
{
    if (remote == nil)
        return;

    if (!locked)
        return;

    NS_DURING
        [remote sendMousePress: 3
                   inDirection: XD_UP];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 *
 */
- (void)otherMouseDown: (NSEvent *)theEvent
{
    if (remote == nil)
        return;

    if (!locked)
        return;

    NS_DURING
        [remote sendMousePress: 2
                   inDirection: XD_DOWN];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 *
 */
- (void)otherMouseUp: (NSEvent *)theEvent
{
    if (remote == nil)
        return;

    if (!locked)
        return;

    NS_DURING
        [remote sendMousePress: 2
                   inDirection: XD_UP];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 *
 */
- (void)scrollWheel: (NSEvent *)theEvent
{
	if (disableScrolling)
		return;
	
    NS_DURING
        if ([theEvent deltaY] > 0.0)
        {
            [remote sendMousePress: 4
                       inDirection: XD_DOWN];
            [remote sendMousePress: 4
                       inDirection: XD_UP];
        }
        else if ([theEvent deltaY] < 0.0)
        {
            [remote sendMousePress: 5
                       inDirection: XD_DOWN];
            [remote sendMousePress: 5
                       inDirection: XD_UP];
        }
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}



@end
