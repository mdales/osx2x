//
// XXController.m
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

#import "XXController.h"
#import "XXView.h"

#import "XXConnection.h"
#import "XXConnectionBag.h"
#import "XXRemoteXWindows.h"
#import "XXRemoteX11Daemon.h"
#import "XXArrowView.h"

#import "keymap.h"

#import <Carbon/Carbon.h>
#import <Security/Security.h>


NSString *OXHostNameKey = @"HostName";
NSString *OXHostNameKey1 = @"HostName1";
NSString *OXHostNameKey2 = @"HostName2";
NSString *OXHostNameKey3 = @"HostName3";
NSString *OXHostNameKey4 = @"HostName4";
NSString *OXCapturePosKey = @"CapturePos";
NSString *OXHideWindowKey = @"HideWindow";
NSString *OXDefaultKeymapKey = @"KeyMap";
NSString *OXArrowColourRedKey = @"ArrowColourRed";
NSString *OXArrowColourGreenKey = @"ArrowColourGreen";
NSString *OXArrowColourBlueKey = @"ArrowColourBlue";
NSString *OXUseKeychainKey = @"UseKeychain";
NSString *OXAutoMiddleClickKey = @"AutoMiddleClick";
NSString *OXArrowTransparencyKey = @"ArrowTransparency";

NSString *OXHotCornerTLKey = @"AvoidTopLeftHC";
NSString *OXHotCornerTRKey = @"AvoidTopRightHC";
NSString *OXHotCornerBLKey = @"AvoidBottomLeftHC";
NSString *OXHotCornerBRKey = @"AvoidBottomRightHC";

NSString *OXEmulateButtonsKey = @"EmulateThreeButtonMouse";
NSString *OXMiddleModifierKey = @"EmulateMiddleModifier";
NSString *OXRightModifierKey = @"EmulateRightModifier";
NSString *OXDisableScrollKey = @"DisableScrollButton";

NSString *OXConnectionNameKey = @"ConnectionName";
NSString *OXConnectionTypeKey = @"ConnectionType";
NSString *OXConnectionPosKey = @"ConnectionPosition";
NSString *OXConnectionReconnectKey = @"ConnectionReconnect";
NSString *OXConnectionPasswordKey = @"ConnectionPassword";

#define CONNECT NSLocalizedStringFromTable(@"Connect", @"osx2x", "Button title for connection")
#define DISCONNECT NSLocalizedStringFromTable(@"Disconnect", @"osx2x", "Button title for disonnection")
#define CONERROR NSLocalizedStringFromTable(@"osx2x Connection Error", @"osx2x", "Title of error dialog box")
#define CONLOST NSLocalizedStringFromTable(@"Connection to remote X Server was lost", @"osx2x", "Warning when we lose connection")
#define CONFAILED NSLocalizedStringFromTable(@"Failed to connect to server %@", @"osx2x", "Warning when we fail to make the connection")
#define CONDUPLICATE NSLocalizedStringFromTable(@"Already have a connection for that edge position", @"osx2x", "Warning when trying to open connection on already used edge")

#define NONE NSLocalizedStringFromTable(@"None", @"osx2x", "Connection direction")
#define EAST NSLocalizedStringFromTable(@"East", @"osx2x", "Connection direction")
#define WEST NSLocalizedStringFromTable(@"West", @"osx2x", "Connection direction")
#define NORTH NSLocalizedStringFromTable(@"North", @"osx2x", "Connection direction")
#define SOUTH NSLocalizedStringFromTable(@"South", @"osx2x", "Connection direction")

const static NSString* OXHostNameKeyList[5] = {@"HostName", @"HostName1", @"HostName2", 
	@"HostName3", @"HostName4"}; 

// Uncomment this to use the X11 daemon controller rather than the standard
// XTest controller
// #define USEX11DAEMON

@implementation XXController

/*------------------------------------------------------------------------------
 *
 */
- init
{
    if ((self = [super init]) != NULL)
    {
        NSMutableDictionary *defaultValues;
        NSMutableDictionary *childNode;
        id objects[4];
        id keys[4];
		float red, green, blue;
        
        connected = FALSE;
        inputLock = FALSE;
		
		hostsList = NULL;

        defaultValues = [NSMutableDictionary dictionary];

        objects[0] = [NSString stringWithString: @"localhost:0"];
        objects[1] = [NSNumber numberWithInt: 0];
        objects[2] = [NSNumber numberWithInt: 0];
		objects[3] = [NSNumber numberWithInt: 0];
        keys[0] = OXConnectionNameKey;
        keys[1] = OXConnectionTypeKey;
        keys[2] = OXConnectionPosKey;
		keys[3] = OXConnectionReconnectKey;
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 4];
        [defaultValues setObject: childNode
                          forKey: OXHostNameKey];

#if 0
        objects[0] = [NSString stringWithString: @""];
        objects[1] = [NSNumber numberWithInt:0];
        objects[2] = [NSNumber numberWithInt:0];
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 3];
        [defaultValues setObject: childNode
                          forKey: OXHostNameKey1];

        objects[0] = [NSString stringWithString: @""];
        objects[1] = [NSNumber numberWithInt:0];
        objects[2] = [NSNumber numberWithInt:0];
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 3];
        [defaultValues setObject: childNode
                          forKey: OXHostNameKey2];

        objects[0] = [NSString stringWithString: @""];
        objects[1] = [NSNumber numberWithInt:0];
        objects[2] = [NSNumber numberWithInt:0];
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 3];
        [defaultValues setObject: childNode
                          forKey: OXHostNameKey3];

        objects[0] = [NSString stringWithString: @""];
        objects[1] = [NSNumber numberWithInt:0];
        objects[2] = [NSNumber numberWithInt:0];
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 3];
        [defaultValues setObject: childNode
                          forKey: OXHostNameKey4];
#endif
		
        [defaultValues setObject: [NSNumber numberWithInt: 0]
                          forKey: OXCapturePosKey];
        [defaultValues setObject: [NSNumber numberWithInt: 0]
                          forKey: OXDefaultKeymapKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXHideWindowKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXUseKeychainKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXAutoMiddleClickKey];
		[[NSColor redColor] getRed: &red
							 green: &green
							  blue: &blue
							 alpha: NULL];
        [defaultValues setObject: [NSNumber numberWithFloat: red]
                          forKey: OXArrowColourRedKey];
        [defaultValues setObject: [NSNumber numberWithFloat: green]
                          forKey: OXArrowColourGreenKey];
        [defaultValues setObject: [NSNumber numberWithFloat: blue]
                          forKey: OXArrowColourBlueKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXHotCornerTLKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXHotCornerTRKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXHotCornerBLKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXHotCornerBRKey];
		[defaultValues setObject: [NSNumber numberWithFloat: 0.3]
						  forKey: OXArrowTransparencyKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXEmulateButtonsKey];
        [defaultValues setObject: [NSNumber numberWithInt: FALSE]
                          forKey: OXDisableScrollKey];
        [defaultValues setObject: [NSNumber numberWithInt: 55]
                          forKey: OXRightModifierKey];
        [defaultValues setObject: [NSNumber numberWithInt: 58]
                          forKey: OXMiddleModifierKey];
        
        [[NSUserDefaults standardUserDefaults] registerDefaults: defaultValues];

        // We should be the delegate to NSApp
        [NSApp setDelegate: self];

        ourwindow = nil;
        timer = nil;
        
        //connectWin = nil;
        remote = nil;
        prefsWin = nil;
        panelOpen = NO;

        connections = [[XXConnectionBag alloc] init];
        
        pn.lowLongOfPSN = pn.highLongOfPSN = kNoProcess;
		
		[self buildHostsListsFromPrefs];
    }

    return self;
}


- (IBAction)preferences: (id)sender
{
    if (prefsWin == nil)
    {
        prefsWin = [[XXPrefsWindowController alloc] init];
        [prefsWin setController: self];
    }

    [prefsWin showWindow: self];
}


/*------------------------------------------------------------------------------
 * aSHR - Delegate for NSApplication. Redisplays the windows.
 */
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication
                    hasVisibleWindows:(BOOL)flag
{
    // Bring that window to the front
    if (ourwindow != nil)
        [ourwindow makeKeyAndOrderFront: nil];

    return NO;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)applicationHide:(NSNotification*)aNotification
{
    if (inputLock)
    {
        // If we lose focus, then remove the input lock, so that upon return
        // we're not having odd behaviour
        [self toggleLock: nil];
    }
}


/*------------------------------------------------------------------------------
 * called from the timer set in connection.
 */
- (void)timerEvent: (NSTimer*)timer
{
}


/*------------------------------------------------------------------------------
 * prefsChanged - Invoked by the preferences window controller when the
 *                preferences have been updated so we can take note.
 */
- (void)prefsChanged
{
	int i;
    NSUserDefaults *defaults;
	
    defaults = [NSUserDefaults standardUserDefaults];
	
	useKeychain = [defaults integerForKey: OXUseKeychainKey];
	autoMiddleClick = [defaults integerForKey: OXAutoMiddleClickKey];
    [ourwindow setHidesOnDeactivate: [defaults integerForKey: OXHideWindowKey]];
    //NSLog(@"Setting window hide to %d\n", [defaults integerForKey: OXHideWindowKey]);
	
	for (i = 0; i < 5; i++)
	{
		XXConnection* connection;
		
		connection = [connections getFromTableRow: i];
		if (connection == nil)
			break;
		
		[[connection getArrowView] updateColour];
	}
}


/*------------------------------------------------------------------------------
 *
 */
- (void)deleteHostsList
{
	HOSTENTRY* temp;
	
	temp = hostsList;
	
	while (temp != NULL)
	{
		HOSTENTRY* prev = temp;
		temp = temp->next;
		[prev->hostname release];
		if (prev->password != nil)
			[prev->password release];
		free(prev);
	}
	
	hostsList = NULL;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)buildHostsListsFromPrefs
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary* hostInfo;
	int i;
	
	if (hostsList != NULL)
		[self deleteHostsList];
	
	for (i = 4; i >=0; i--)
	{
		HOSTENTRY* temp;
		id val;
		
		val = [defaults objectForKey: (NSString*)OXHostNameKeyList[i]];
		
		if (val == nil)
			continue;
		
		// Is this old prefs (NSString) or new prefs (NSDictionary)?
		if ([val isKindOfClass: [NSDictionary class]] == YES)
		{
			hostInfo = (NSDictionary*)val;
		}
		else if ([val isKindOfClass: [NSString class]] == YES)
		{
			id objects[4];
			id keys[4];
			NSMutableDictionary *childNode;
			
			// We really want to create a NSDictionary for the string
			
			objects[0] = [NSString stringWithString: val];
			objects[1] = [NSNumber numberWithInt: 0];
			objects[2] = [NSNumber numberWithInt: 0];
			objects[3] = [NSNumber numberWithInt: 0];
			keys[0] = OXConnectionNameKey;
			keys[1] = OXConnectionTypeKey;
			keys[2] = OXConnectionPosKey;
			keys[3] = OXConnectionReconnectKey;
			childNode = [NSMutableDictionary dictionaryWithObjects: objects
														   forKeys: keys
															 count: 4];
			[defaults setObject: childNode
						 forKey: (NSString*)OXHostNameKeyList[i]];
			
			
			hostInfo = [defaults dictionaryForKey: (NSString*)OXHostNameKeyList[i]];
			
		}
		else
		{
			NSLog(@"Much weirdness in the plist file\n");
			continue;
		}
		
		if (hostInfo == nil)
			continue;
		
		temp = (HOSTENTRY*)malloc(sizeof(HOSTENTRY));
		temp->prev = NULL;
		temp->hostname = [[NSString alloc] initWithString: [hostInfo objectForKey: OXConnectionNameKey]];
		temp->side = [[hostInfo objectForKey: OXConnectionPosKey] intValue];
		temp->type = [[hostInfo objectForKey: OXConnectionTypeKey] intValue];
		temp->autoreconnect = [[hostInfo objectForKey: OXConnectionReconnectKey] intValue];
		if (temp->type == XXConnectionVNC)
		{
			NSString* password = nil;
			
			//password = [hostInfo objectForKey: OXConnectionPasswordKey];
			if (password == nil)
				password = @"";
			
			temp->password = [[NSString alloc] initWithString: password];
		}
		else
			temp->password = nil;
	
		if (hostsList != NULL)
			hostsList->prev = temp;
		temp->next = hostsList;
		hostsList = temp;
	}
}


/*------------------------------------------------------------------------------
 *
 */
- (void)doAutoReconnect
{
	HOSTENTRY* host;
    XXConnection *connection;
	
	for (host = hostsList; host != NULL; host = host->next)
	{
		if (host->autoreconnect)
		{
			
			// first see if we already have somethign running in that position
			if ([connections getFromPosition: host->side] != nil)
				continue;
			
			if ((host->type == XXConnectionVNC) && useKeychain)
			{
				NSString *serviceName;
				NSString *accountName;
				UInt32 length;
				void* data;
				
				// At this stage we won't have passwords for VNC connections!
				serviceName = @"osx2x";
				accountName = [NSString stringWithFormat: @"vnc://%@", host->hostname];
			
				SecKeychainFindGenericPassword (NULL, [serviceName cStringLength], [serviceName cString],
												[accountName cStringLength], [accountName cString],
												&length, &data, NULL);
			
				host->password = [[NSString alloc] initWithCString: data
															length: length];
			}
			
			
			// Attempt the connection
			connection = [[XXConnection alloc] initWithHost: host->hostname
											   withPosition: host->side
											   withUsername: @""
											   withPassword: host->password
												   withType: host->type
											  forController: self];
			
			if (connection == nil)
				continue;
			
			if ([connections count] == 0)
			{
				[copyMenu setEnabled: TRUE];
				[pasteMenu setEnabled: TRUE];
				[toggleMenu setEnabled: TRUE];
				[disconnectButton setEnabled: ([hostnameList selectedRow] != -1)];
				[disconnectMenu setEnabled: ([hostnameList selectedRow] != -1)];
			}
			
			isRelative = YES;
			
			// We have a periodic check to make sure the capture window is in the
			// forground. Hacky, but what the hey
			if (timer == nil)
				timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
														 target: self
													   selector: @selector(timerEvent:)
													   userInfo: nil
														repeats: YES];
			[connections addConnection: connection];
			
			[hostnameList reloadData];
		}
	}
}


/*------------------------------------------------------------------------------
 *
 */
- (void)awakeFromNib
{
    NSUserDefaults *defaults;
    OSStatus err;
    EventHotKeyRef or;
    EventHotKeyID gMyHotKeyID;

    defaults = [NSUserDefaults standardUserDefaults];
    ourwindow = [xxView window];
    [xxView setController: self];

    [ourwindow setHidesOnDeactivate: [defaults integerForKey: OXHideWindowKey]];
	useKeychain = [defaults integerForKey: OXUseKeychainKey];
	autoMiddleClick = [defaults integerForKey: OXAutoMiddleClickKey];

    // Now set up to receive notification of when we lose control (either we're
    // hidden or the user cmd-tabbed away)
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(applicationHide:)
                                                 name: NSApplicationWillResignActiveNotification
                                               object: NSApp];

    gMyHotKeyID.signature = 'lUIk';
    gMyHotKeyID.id = 1;

    [NSApp setController: self];
    
    err=RegisterEventHotKey(109, cmdKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &or);

    // Can't use this stuff until connected to the server
    [[copyMenu menu] setAutoenablesItems: NO];
    [[disconnectMenu menu] setAutoenablesItems: NO];

    [copyMenu setEnabled: FALSE];
    [pasteMenu setEnabled: FALSE];
    [toggleMenu setEnabled: FALSE];
	
	[disconnectMenu setEnabled: FALSE];
	[enableAutoMenu setEnabled: FALSE];
	[disableAutoMenu setEnabled: FALSE];

    // Set up a watch for a copy notification from one of the remotes
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(copyNotification:)
                                                 name: kCopyNotification
                                               object: NSApp];

    if ([connections count] == 0)
    {
        [disconnectButton setEnabled: FALSE];
		[disconnectMenu setEnabled: FALSE];
    }

    [hostnameList setDataSource: connections];
	
    keymap_init();
    keymap_set([defaults integerForKey: OXDefaultKeymapKey]);
	
	[self doAutoReconnect];
	
	[self hostSelectionChange: nil];
}




/*------------------------------------------------------------------------------
 * setActiveController - called by an XXConnection object (noted in sender)
 *                       when the mouse has entered it's region.
 */
- (void)setActiveController: (id)sender
{
    if (panelOpen)
        return;
    
    remote = sender;
    
	if ([sender getPosition] != XXWindowNone)
	{
		[self noteFrontApp];
		
		[sender setArrowVisible: YES];
		activeArrowView = [sender getArrowView];
		
		isRelative = NO;
		
		[[activeArrowView window] makeKeyAndOrderFront: nil];
		[activeArrowView setController: self];
		
		[activeArrowView setRemote: [sender getRemoteController]];
		[activeArrowView setCaptureScreen: [sender getScreenSize]];
		
		lockLocation = [NSEvent mouseLocation];
		[activeArrowView setLockLocation: lockLocation];
		
		[self toggleLock: nil];
	}
	else
	{
		[self noteFrontApp];

		if (ourwindow != nil)
			[ourwindow makeKeyAndOrderFront: nil];

		[NSApp activateIgnoringOtherApps: YES];
		isRelative = NO;

		[xxView setRemote: [sender getRemoteController]];
		[xxView setCaptureScreen: [sender getScreenSize]];
		
		lockLocation = [NSEvent mouseLocation];
		[xxView setLockLocation: lockLocation];

		[self toggleLock: nil];
	}    
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)toggleWithoutMouse:(id)sender
{
	XXConnection *con;
	
	if (remote == nil)
	{		
		// Find out if there is a connection for it
		con = [connections getFromPosition: XXWindowNone];
		
		if (con == nil)
			return;
		
		[self setActiveController: con];
	}
	else
	{
		// Don't toggle if the active controller wasn't started from
		// a togglewithoutmouse
		if ([remote getPosition] != XXWindowNone)
			return;
		
		[self toggleLock: nil];
		[self promoteFrontApp];
	}
}


/*------------------------------------------------------------------------------
 *  This used to be called by a menu item, but is now just an internal function.
 *  The menu item now called toggleWithoutMouse
 */
- (IBAction)toggleLock:(id)sender
{
    if (remote != nil)
    {
        XXWindowPos capturePos = [remote getPosition];        
		
		if (activeArrowView != nil)
			[activeArrowView toggleLockWithPosition: isRelative == NO ? capturePos : XXWindowNone];
        else
			[xxView toggleLockWithPosition: isRelative == NO ? capturePos : XXWindowNone];
		
        inputLock = !inputLock;			
		
		if (!inputLock)
		{
			activeArrowView = nil;
			[remote setArrowVisible: NO];
			remote = nil;
		}
    }
    else
    {
		
#if 0
		// XXX: This code is depricated since I added the ability to specify connections
		// that auto connect when you launch osx2x. This was always a hack, so the other
		// way is now the done thing.
		
        // They attempted to use a connection that's not there - should we autoconnect?
        if ([[NSUserDefaults standardUserDefaults] integerForKey: OXAutoConnectKey])
        {
            // Yes we should
            [self connect: nil];

            // If successful then now toggle the lock
            if (remote != nil)
            {
                [xxView toggleLockWithPosition: XXWindowNone];
                inputLock = !inputLock;
            }
        }
#endif
    }
    isRelative = YES;
	
}



- (void)noteFrontApp
{
#if 0
    unsigned char procname[256];
    ProcessInfoRec pi;
#endif
    
    memset(&pn, 0, sizeof(pn));
    GetFrontProcess(&pn);

#if 0
    pi.processInfoLength = sizeof(ProcessInfoRec);
    memset(&procname, 0, 256);
    pi.processName = (StringPtr)&procname;
    GetProcessInformation(&pn, &pi);

    NSLog(@"Front process name is: %s\n", &(procname[1]));
#endif
}


- (void)promoteFrontApp
{
    if (pn.lowLongOfPSN != kNoProcess)
    {
        // Restore the front process, but take care not to change the
        // window order any more than neccessary.
        SetFrontProcessWithOptions(&pn, kSetFrontProcessFrontWindowOnly);
        pn.lowLongOfPSN = pn.highLongOfPSN = kNoProcess;
    }
}


/*------------------------------------------------------------------------------
 *
 */
- (void)setPanelForHostEntry: (HOSTENTRY*)host
{
	[panelPositionList selectItemAtIndex: host->side];
	[panelConnectionList selectItemAtIndex: host->type];
	[panelAutoreconnectBox setState: (host->autoreconnect ? NSOnState : NSOffState)];
	[self connectionTypeChange: nil];
	if ((host->type == XXConnectionVNC) && useKeychain)
	{
		NSString *serviceName;
		NSString *accountName;
		UInt32 length;
		void* data;
		
		// We lazily load the VNC password here, so the user isn't bothered
		// by keychain access requests if they don't attempt to use a VNC
		// connection
		
		serviceName = @"osx2x";
		accountName = [NSString stringWithFormat: @"vnc://%@", host->hostname];
		
		SecKeychainFindGenericPassword (NULL, [serviceName cStringLength], [serviceName cString],
										[accountName cStringLength], [accountName cString],
										&length, &data, NULL);
		
		host->password = [[NSString alloc] initWithCString: data
													length: length];
		
		// should set password here, but ignoring for now
		[panelPasswordBox setStringValue: host->password];
	}
	else
	{
		[panelPasswordBox setStringValue: @""];
	}
}


/*------------------------------------------------------------------------------
 * connect - called to open a new connection. Assume that this button is
 *           disabled once the user has the maximum number of connections open.
 */
- (IBAction)connect: (id)sender
{
    panelOpen = YES;
	HOSTENTRY* temp;
	
	// First build the interface based of previous preferences
	[panelHostnameList removeAllItems];
	for (temp = hostsList; temp != NULL; temp = temp->next)
		[panelHostnameList addItemWithObjectValue: temp->hostname];
	[panelHostnameList selectItemAtIndex: 0];
	[self setPanelForHostEntry: hostsList];
	
    [NSApp beginSheet: panel
       modalForWindow: [xxView window]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
    [NSApp runModalForWindow: panel];
    // Sheet is up here.
    [NSApp endSheet: panel];
    [panel orderOut: self];

}


- (IBAction)cancelPanel: (id)sender
{
    [NSApp stopModal];
    panelOpen = NO;
}


// User has changed the type of connection they want, so
// set the activity of the name/password panels appropriately
- (IBAction)connectionTypeChange: (id)sender
{
	XXConnectionType type;
	
	type = (XXConnectionType)[panelConnectionList indexOfSelectedItem];
	
	switch (type)
	{
		case XXConnectionVNC:
			[panelUsernameBox setEnabled: FALSE];
			[panelPasswordBox setEnabled: TRUE];
			break;
			
		case XXConnectionX11: default:
			[panelUsernameBox setEnabled: FALSE];
			[panelPasswordBox setEnabled: FALSE];
			break;
	}
}



/*------------------------------------------------------------------------------
 *
 */
- (IBAction)connectionHostChange: (id)sender
{
	HOSTENTRY* host;
	NSString* name;
	
	name = [panelHostnameList stringValue];
	
	// See if we can find a matching host entry for the new name
	for (host = hostsList; host != NULL; host = host->next)
		if ([host->hostname caseInsensitiveCompare: name] == NSOrderedSame)
		{
			[self setPanelForHostEntry: host];
			return;
		}
}


/*------------------------------------------------------------------------------
 * note we assume that the name came from a combo box and thus needs retaining
 */
- (void)storeLatestHostEntryWithName: (NSString*)name
						withPosition: (XXWindowPos)pos
							withType: (XXConnectionType)type
						withPassword: (NSString*)password
					   withReconnect: (BOOL)autoreconnect
{
	HOSTENTRY* host;
	int i;
	
	// First, is an entry for this host in the list?
	for (host = hostsList; host != NULL; host = host->next)
		if ([host->hostname caseInsensitiveCompare: name] == NSOrderedSame)
		{
			// found a match - update its entries and move it to the head of the list
			host->side = pos;
			host->type = type;
			host->autoreconnect = autoreconnect;
			if (type == XXConnectionVNC)			
				host->password = password;
			
			[password retain];
			
			while (host->prev != NULL)
			{
				// This took me three diagrams to get right 
				host->prev->next = host->next;
				if (host->next != NULL)
					host->next->prev = host->prev;
				if (host->prev->prev != NULL)
					host->prev->prev->next = host;
				host->next = host->prev;
				host->prev = host->prev->prev;
				host->next->prev = host;
			}
			hostsList = host;
			return;
		}
	
	// If we got here then there was no match.
	
	// The first task is to see if we already have five entries - if so, ditch
	// the last one
	for (i = 0, host = hostsList; host != NULL; host = host->next, i++)
		;
	if (i == 5)
	{
		// I know, I know, this is ugly :)
		[hostsList->next->next->next->next->hostname release];
		if (hostsList->next->next->next->next->password != nil)
			[hostsList->next->next->next->next->password release];
		free(hostsList->next->next->next->next);
		hostsList->next->next->next->next = NULL;
	}
	host = (HOSTENTRY*)malloc(sizeof(HOSTENTRY));
	host->next = hostsList;
	host->prev = NULL;
	hostsList->prev = host;
	hostsList = host;
	
	[name retain];
	host->hostname = name;
	host->side = pos;
	host->type = type;
	host->autoreconnect = autoreconnect;
}


/*------------------------------------------------------------------------------
 * storeHostsLists - writes the current list of host entries to the user 
 *					 defaults.
 */
- (void)storeHostsLists
{
	int i;
	HOSTENTRY* host;
	id objects[4];
	id keys[4];
	NSMutableDictionary* childNode;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	
	keys[0] = OXConnectionNameKey;
	keys[1] = OXConnectionTypeKey;
	keys[2] = OXConnectionPosKey;
	keys[3] = OXConnectionReconnectKey;
	
	for (host = hostsList, i = 0; host != NULL; host = host->next, i++)
	{
		objects[0] = host->hostname;
		objects[1] = [NSNumber numberWithInt: host->type];
		objects[2] = [NSNumber numberWithInt: host->side];
		objects[3] = [NSNumber numberWithInt: host->autoreconnect];
		
        childNode = [NSMutableDictionary dictionaryWithObjects: objects
                                                       forKeys: keys
                                                         count: 4];
		
		[defaults setObject: childNode
					 forKey: (NSString*)OXHostNameKeyList[i]];
		
		if (useKeychain && (host->type == XXConnectionVNC))
		{
			NSString *serviceName;
			NSString *accountName;
			
			serviceName = @"osx2x";
			accountName = [NSString stringWithFormat: @"vnc://%@", host->hostname];
			
			// we want to store the VNC password here. Now, for VNC servers
			// with empty passwords we could store nothing, but then that
			// makes it easy to infer that the password is nothing, so I'll
			// store the blank password in the keychain anyway
			
			SecKeychainAddGenericPassword(NULL, [serviceName cStringLength], [serviceName cString],
										  [accountName cStringLength], [accountName cString],
										  [host->password cStringLength], [host->password cString],
										  NULL);
		}
	}
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)connectPanel:(id)sender
{
    XXConnection *connection;
    XXWindowPos position;
    XXConnectionType contype;
    NSString *hostname, *username, *password;
	BOOL autoreconnect;

    hostname = [panelHostnameList stringValue];
    username = [panelUsernameBox  stringValue];
    password = [panelPasswordBox  stringValue];
    position = (XXWindowPos)[[panelPositionList selectedItem] tag];
    contype = (XXConnectionType)[panelConnectionList indexOfSelectedItem];
	autoreconnect = [panelAutoreconnectBox state] == NSOnState;

	[self storeLatestHostEntryWithName: hostname
						  withPosition: position
							  withType: contype
						  withPassword: password
						 withReconnect: autoreconnect];
	[self storeHostsLists];
	
    [NSApp stopModal];
    panelOpen = NO;

    // First of all, check whether a connection at that position exists
    if ([connections getFromPosition: position] != nil)
    {
        NSRunCriticalAlertPanel(CONERROR,
                                CONDUPLICATE,
                                nil, nil, nil, hostname);
        return;
    }

    connection = [[XXConnection alloc] initWithHost: hostname
                                       withPosition: position
                                       withUsername: username
                                       withPassword: password
                                           withType: contype
                                      forController: self];

    if (connection == nil)
    {
        NSRunCriticalAlertPanel(CONERROR,
                                CONFAILED,
                                nil, nil, nil, hostname);
        return;
    }


    if ([connections count] == 0)
    {
        [copyMenu setEnabled: TRUE];
        [pasteMenu setEnabled: TRUE];
        [toggleMenu setEnabled: TRUE];
        [disconnectButton setEnabled: ([hostnameList selectedRow] != -1)];
        [disconnectMenu setEnabled: ([hostnameList selectedRow] != -1)];
    }

    isRelative = YES;

    // We have a periodic check to make sure the capture window is in the
    // forground. Hacky, but what the hey
    if (timer == nil)
        timer = [NSTimer scheduledTimerWithTimeInterval: 0.5
                                                 target: self
                                               selector: @selector(timerEvent:)
                                               userInfo: nil
                                                repeats: YES];
    [connections addConnection: connection];

    [hostnameList reloadData];
	[self hostSelectionChange: nil];
}


/*------------------------------------------------------------------------------
 * disconnect - called to remove a connection. Assume that this is disabled if
 *              there is nothing to disconnect.
 */
- (IBAction)disconnect: (id)sender
{
    int selected;
    XXConnection* connection;
    
    // See what item is selected (set in IB to only allow one)
    selected = [hostnameList selectedRow];

    if (selected == -1)
    {
        // should be prevented from happening
        return;
    }

    connection = [connections getFromTableRow: selected];
    if (connection == nil)
    {
        // hmmm
        return;
    }

    // Remove this from the bag of connections and destroy it
    [connections removeConnection: connection];
    [hostnameList reloadData];
    [connection disconnect];
    [connection release];

    // Now see what UI stuff needs updating
    if ([connections count] == 0)
    {
		
        [copyMenu setEnabled: FALSE];
        [pasteMenu setEnabled: FALSE];
        [toggleMenu setEnabled: FALSE];
        [disconnectButton setEnabled: FALSE];
        [disconnectMenu setEnabled: FALSE];

        [timer invalidate];
        timer = nil;
    }
	else
	{
		NSString* hostname;
		HOSTENTRY* host;
		XXConnection* connection;
		
		[hostnameList setEnabled: ([hostnameList selectedRow] != -1)];
	
		if ([hostnameList selectedRow] != -1)
		{		
			// What's the name of the currently selected host?
			connection = [connections getFromTableRow: selected];
			hostname = [connection getHostName];
			for (host = hostsList; host != NULL; host = host->next)
			{
				if ([hostname caseInsensitiveCompare: host->hostname] == NSOrderedSame)
				{
					if (host->autoreconnect)
					{
						[enableAutoMenu setEnabled: FALSE];
						[disableAutoMenu setEnabled: TRUE];
					}
					else
					{
						[enableAutoMenu setEnabled: TRUE];
						[disableAutoMenu setEnabled: FALSE];
					}
					break;
				}
			}
		}
	}
}


- (IBAction)enableAutoReconnect: (id)sender
{
	NSString* hostname;
	HOSTENTRY* host;
	XXConnection* connection;
	
	connection = [connections getFromTableRow: [hostnameList selectedRow]];
	hostname = [connection getHostName];
	for (host = hostsList; host != NULL; host = host->next)
	{
		if ([hostname caseInsensitiveCompare: host->hostname] == NSOrderedSame)
		{
			host->autoreconnect = TRUE;
			[self storeHostsLists];
			
			[enableAutoMenu setEnabled: FALSE];
			[disableAutoMenu setEnabled: TRUE];
			
			break;
		}
	}
}


- (IBAction)disableAutoReconnect: (id)sender
{
	NSString* hostname;
	HOSTENTRY* host;
	XXConnection* connection;
	
	connection = [connections getFromTableRow: [hostnameList selectedRow]];
	hostname = [connection getHostName];
	for (host = hostsList; host != NULL; host = host->next)
	{
		if ([hostname caseInsensitiveCompare: host->hostname] == NSOrderedSame)
		{
			host->autoreconnect = FALSE;
			[self storeHostsLists];
			
			[enableAutoMenu setEnabled: TRUE];
			[disableAutoMenu setEnabled: FALSE];
			
			break;
		}
	}
}


- (IBAction)hostSelectionChange:(id)sender
{
    int selected;
	XXConnection* connection;
	NSString* hostname;
	HOSTENTRY* host;
	
    // See what item is selected (set in IB to only allow one)
    selected = [hostnameList selectedRow];
	
    [disconnectButton setEnabled: (selected != -1)];
    [disconnectMenu setEnabled: (selected != -1)];
	
	// What's the name of the currently selected host?
    connection = [connections getFromTableRow: selected];
	hostname = [connection getHostName];
	for (host = hostsList; host != NULL; host = host->next)
	{
		if ([hostname caseInsensitiveCompare: host->hostname] == NSOrderedSame)
		{
			if (host->autoreconnect)
			{
				[enableAutoMenu setEnabled: FALSE];
				[disableAutoMenu setEnabled: TRUE];
			}
			else
			{
				[enableAutoMenu setEnabled: TRUE];
				[disableAutoMenu setEnabled: FALSE];
			}
			break;
		}
	}
}


- (void)criticalDisconnect
{
    // close connections
    connected = FALSE;
    [connectButton setTitle: CONNECT];

    if (inputLock)
        [self toggleLock: nil];

    [remote disconnect];
    [remote release];
    remote = nil;

    [copyMenu setEnabled: FALSE];
    [pasteMenu setEnabled: FALSE];
    [toggleMenu setEnabled: FALSE];
    //[captureList setEnabled: TRUE];
    [hostnameList setEnabled: TRUE];

    [timer invalidate];
    timer = nil;
    
    NSRunCriticalAlertPanel(CONERROR,
                            CONLOST,
                            nil, nil, nil, nil);
}


/*------------------------------------------------------------------------------
 *
 */
- (BOOL)isLocked
{
    return inputLock;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)dealloc
{
    if (remote != nil)
    {
        [remote disconnect];
        [remote release];
    }
	
	if (hostsList != NULL)
		[self deleteHostsList];
    
    [super dealloc];
}


/*------------------------------------------------------------------------------
 *
 */
- (void)writeToPasteboard:(NSPasteboard *)pb
                   string:(NSString*)str
{
    // declare types
    [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
               owner: self];

    // copy data to pasteboard
    [pb setString: str
          forType: NSStringPboardType];
}


/*------------------------------------------------------------------------------
 *
 */
- (BOOL)readFromPasteboard:(NSPasteboard *)pb
                    string:(NSString**)str
{
    NSString *value;
    NSString *type;

    // Is there a string on the pasteboard?
    type = [pb availableTypeFromArray: [NSArray arrayWithObject: NSStringPboardType]];
    //NSLog(@"read type = %@", type);

    if (type)
    {
        // Read the string from the pasteboard
        value = [pb stringForType: NSStringPboardType];
        [value retain];
        *str = value;
        return YES;
    }

    return NO;
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)copyFromX:(id)sender
{
    NS_DURING
        [[remote getRemoteController] copyFromRemote];
    NS_HANDLER
        [self criticalDisconnect];
    NS_ENDHANDLER
}


/*------------------------------------------------------------------------------
 * copyData - Called when the X world has provided us with data
 */
- (void)copyNotification: (NSNotification*)aNotification
{
    NSString *sdata;
    NSData   *data;

    NSLog(@"Copying data");
    
    data =  [[aNotification userInfo] objectForKey: kCopyData];

    sdata = [NSString stringWithCString: [data bytes]];

    [self writeToPasteboard: [NSPasteboard generalPasteboard]
                     string: sdata];
}


/*------------------------------------------------------------------------------
 * pasteToX: Ooops - wrong method name in nib
 */
- (IBAction)pasteFromX:(id)sender
{
    NSString *str;
    
    if ([self readFromPasteboard: [NSPasteboard generalPasteboard]
                          string: &str])
    {
        char* data;
        int length = [str cStringLength]; 
		NSLog(@"clipboard data was: %@", str);

        data = (char*)malloc(length + 1);
        [str getCString: data];

        NS_DURING
            [[remote getRemoteController] pasteToRemote: data];
        NS_HANDLER
            [self criticalDisconnect];
        NS_ENDHANDLER
    }
	else
	{
		NSLog(@"Failed to copy from clipboard!");
	}
}

- (IBAction)sendControlAltDelete:(id)sender
{
	id controller = [remote getRemoteController];
	
	if( [controller respondsToSelector: @selector(sendControlAltDelete)]) 
	{
		[controller sendControlAltDelete];
	}
}

@end
