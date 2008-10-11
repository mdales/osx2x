//
// XXController.h
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

/* XXController */

#import <Cocoa/Cocoa.h>
#import "xcode.h"
#import "XXAbstractRemote.h"
#import "XXPrefsWindowController.h"

extern NSString *OXHostNameKey;
extern NSString *OXHostNameKey1;
extern NSString *OXHostNameKey2;
extern NSString *OXHostNameKey3;
extern NSString *OXHostNameKey4;
extern NSString *OXCapturePosKey;
extern NSString *OXHideWindowKey;
//extern NSString *OXAutoConnectKey;
extern NSString *OXConnectionNameKey;
extern NSString *OXConnectionTypeKey;
extern NSString *OXConnectionPosKey;
extern NSString *OXDefaultKeymapKey;
extern NSString *OXArrowColourRedKey;
extern NSString *OXArrowColourGreenKey;
extern NSString *OXArrowColourBlueKey;
extern NSString *OXUseKeychainKey;
extern NSString *OXAutoMiddleClickKey;
extern NSString *OXHotCornerTLKey;
extern NSString *OXHotCornerTRKey;
extern NSString *OXHotCornerBLKey;
extern NSString *OXHotCornerBRKey;
extern NSString *OXArrowTransparencyKey;
extern NSString *OXEmulateButtonsKey;
extern NSString *OXMiddleModifierKey;
extern NSString *OXRightModifierKey;
extern NSString *OXDisableScrollKey;
extern NSString *OXConnectionReconnectKey;

// Enumeration for noting where we're capturing from. This enumeration matches the tag
// on the item in the GUI's menu, so numbers here are important
enum XXWPTAG {XXWindowNone = 0, XXWindowEast = 1, XXWindowWest = 2, XXWindowNorth = 3, XXWindowSouth = 4};
typedef enum XXWPTAG XXWindowPos;

// Enumeration for the connection type we use. This enumeration matches the tag's used
// on the GUI, so the numbers here are important
enum XXCTTAG {XXConnectionX11 = 0, XXConnectionVNC = 1, XXConnectionDaemon = 2};
typedef enum XXCTTAG XXConnectionType;

// This is used to store a linked list of defaults so that the panel settings can be
// changed when one is selected from the host list
typedef struct HETAG
{
	struct HETAG* next;
	NSString* hostname;
	NSString* password;
	XXWindowPos side;
	XXConnectionType type;
	struct HETAG* prev;    // Doubally linked to make sorting easier
	BOOL autoreconnect;
} HOSTENTRY;

@class XXConnection;
@class XXConnectionBag;

@interface XXController : NSObject
{
    IBOutlet id xxView;
    IBOutlet id connectButton;
    IBOutlet id disconnectButton;
    IBOutlet id hostnameList;
	
    IBOutlet id copyMenu;
    IBOutlet id pasteMenu;
    IBOutlet id toggleMenu;
	IBOutlet id enableAutoMenu;
	IBOutlet id disableAutoMenu;
	IBOutlet id disconnectMenu;
	
    IBOutlet id panel;
    IBOutlet id panelHostnameList;
    IBOutlet id panelPositionList;
    IBOutlet id panelConnectionList;
    IBOutlet id panelUsernameBox;
    IBOutlet id panelPasswordBox;
    IBOutlet id panelAutoreconnectBox;
	
    BOOL          connected;
    BOOL          inputLock;
    NSTimer       *timer;
    BOOL          isRelative;
    NSPoint  	  lockLocation;
    BOOL	      panelOpen;
	BOOL		  useKeychain;
	BOOL		  autoMiddleClick;

	id activeArrowView;
	
    XXConnection* remote;

    XXConnectionBag* connections;
    
    ProcessSerialNumber pn;

    XXPrefsWindowController* prefsWin;
    //XXConnectWindowController* connectWin;
    
    NSWindow* ourwindow;
    //NSString* hosts[5];
	
	HOSTENTRY* hostsList;
}
- (IBAction)toggleLock:(id)sender;
- (IBAction)toggleWithoutMouse:(id)sender;
- (IBAction)connect:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)copyFromX:(id)sender;
- (IBAction)pasteFromX:(id)sender;
- (IBAction)preferences:(id)sender;
- (IBAction)hostSelectionChange:(id)sender;
- (IBAction)connectionTypeChange: (id)sender;
- (IBAction)connectionHostChange: (id)sender;


- (IBAction)cancelPanel:(id)sender;
- (IBAction)connectPanel:(id)sender;

- (void)timerEvent: (NSTimer*)nstimer;

- (void)criticalDisconnect;
- (BOOL)isLocked;

#ifdef OLD_SKOOL
- (void)copyData: (char*)data;
#endif

- (void)setActiveController: (id)connection;

- (void)writeToPasteboard:(NSPasteboard *)pb
                   string:(NSString*)str;
- (BOOL)readFromPasteboard:(NSPasteboard *)pb
                    string:(NSString**)str;

- (void)noteFrontApp;
- (void)promoteFrontApp;

- (void)prefsChanged;
- (void)buildHostsListsFromPrefs;

- (IBAction)sendControlAltDelete:(id)sender;

#if 0
- (void)connectCallbackWithHostname: (NSString*)hostname
                       withPosition: (NSNumber*)position
                           withType: (NSNumber*)type
                       withUsername: (NSString*)username
                  withPassword: (NSString*)password;
#endif
@end 
