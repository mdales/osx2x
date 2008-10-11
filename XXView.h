//
// XXView.h
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

#import <Cocoa/Cocoa.h>
#import "XXController.h"

@interface XXView : NSView
{
    NSPoint oldMouse;
    BOOL locked;
    BOOL justLocked;
    char keyState[128];
	char hackedKeyState[128]; // used for pressAllFlags
    XXWindowPos winPos;
    BOOL isRelative;
#ifdef OLD_SKOOL
    DPYINFO* display;
    XXSize xScreenSize;
    XXSize cursorPos;
#else
    NSRect screenSize;
    NSPoint cursorPos;
#endif
    NSPoint lockLocation;
    CGRect captScreen;
    CGPoint lockPos;
	
    BOOL mouseEmulation;
    int middleModifier, rightModifier;
	BOOL disableScrolling;
	
    id remote;
    
    XXController* controller;
}
- (void)toggleLockWithPosition: (XXWindowPos)position;
#ifdef OLD_SKOOL
- (void)setXDisplay:(DPYINFO*)disp;
#endif
- (void)setController: (XXController*)cont;
- (void)setLockLocation: (NSPoint)loc;
- (void)setCaptureScreen: (CGRect)s;
- (void)unpressAllFlags;
- (void)pressAllFlags;
- (void)setRemote: (id)r;
- (void)updatePrefs;

@end
