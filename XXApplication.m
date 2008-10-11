//
// XXpplication.m
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
#import "XXApplication.h"

// Defined here until I find a more sensible place to put it
NSString *kCopyNotification = @"Copy From Remote Machine";
NSString *kCopyData = @"Copy data";


enum {
    // NSEvent subtypes for hotkey events (undocumented).
    kEventHotKeyPressedSubtype = 6,
    kEventHotKeyReleasedSubtype = 9,
}; 

@implementation XXApplication

- (void)setController:(XXController*)ctrl
{
    xxCtrl = ctrl;
}


- (void)sendEvent:(NSEvent *)theEvent
{
    if ([theEvent type] == NSSystemDefined && [theEvent subtype] == kEventHotKeyPressedSubtype)
    {
        // we only respond to a single hotkey, so we know this'll be the active thing

        if ([xxCtrl isLocked])
        {
            [xxCtrl toggleLock: nil];
            //[self hide: nil];
            [xxCtrl promoteFrontApp];
        }
        else
        {
            [xxCtrl noteFrontApp];
            [self activateIgnoringOtherApps: YES];
            [xxCtrl toggleLock: nil];
        }

    }

    [super sendEvent:theEvent]; // YOU MUST CALL THIS OR YOU WILL EAT EVENTS!
}

@end
