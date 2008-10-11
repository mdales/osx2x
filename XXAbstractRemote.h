//
// XXAbstractRemote.h
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

// This Protocol defines the interface for a control connection to a remote
// machine. Connection objects are requred to adhear to this protocol. The interface
// is mostly self explanitory, but there are two non-obvious points:
//
// 1) Methods may throw and exception of type NSException with the name @"ConnectionLost"
//    which indicates that there was an error communicating.
//
// 2) The copyOnRemote will cause a notification to happen with the name kCopyNotification.
//    The userData entry of the notification will contain a dictionary with the data held
//    for key kCopyData in an NSData object.


#import <Cocoa/Cocoa.h>

enum XXDIRECTION {XD_UP = 0, XD_DOWN = 1};

// Actually defined in XXApplication.m for now
extern NSString *kCopyNotification;
extern NSString *kCopyData;

@protocol XXAbstractRemote


- (NSRect)displaySize;
- (void)moveCursorRelative: (NSPoint)position;
- (void)moveCursorAbsolute: (NSPoint)position;
- (void)sendKeyPress: (int)keycode
         inDirection: (enum XXDIRECTION)direction;
- (void)sendMousePress: (int)button
           inDirection: (enum XXDIRECTION)direction;
- (void)pasteToRemote: (char*)data;
- (void)copyFromRemote;
- (void)disconnect;

@end
