//
//  XXPrefsWindowController.m
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

#import "XXPrefsWindowController.h"
#import "XXController.h"
#import "keymap.h"
#import "XXAutoConnectBag.h"

@implementation XXPrefsWindowController

static const int modifierMap[5] = {58, 55, 59, 63, 56};

const static NSString* OXHostNameKeyList[5] = {@"HostName", @"HostName1", @"HostName2", 
    @"HostName3", @"HostName4"}; 

/*------------------------------------------------------------------------------
 *
 */
- (id)init
{
    if (self = [super initWithWindowNibName:@"Preferences"])
    {
        xxController = nil;
        connectBag = [[XXAutoConnectBag alloc] init];
    }
    
    return self;
}


/*------------------------------------------------------------------------------
 *
 */
- (void)dealloc
{
    [connectBag release];
    [super dealloc];
}


/*------------------------------------------------------------------------------
 *
 */
- (void)setController: (id)controller
{
    xxController = controller;
}


/*------------------------------------------------------------------------------
 * windowDidLoad - once the nib file has loaded our window read the defaults.
 */
- (void)windowDidLoad
{
    NSUserDefaults *defaults;
	float red, green, blue;
	NSColor* colour;
	int mod, i;

    defaults = [NSUserDefaults standardUserDefaults];

	[arrowTransSlider setFloatValue: [defaults floatForKey: OXArrowTransparencyKey]];
	
	red = [defaults floatForKey: OXArrowColourRedKey];
	green = [defaults floatForKey: OXArrowColourGreenKey];
	blue = [defaults floatForKey: OXArrowColourBlueKey];
	colour = [NSColor colorWithCalibratedRed: red
									   green: green
										blue: blue
									   alpha: 1.0];
	[colorSelector setColor: colour];
    
	[hideWindowCB setState: [defaults boolForKey: OXHideWindowKey]];
	[useKeychainCB setState: [defaults boolForKey: OXUseKeychainKey]];
    [mapList selectItemAtIndex: [defaults integerForKey: OXDefaultKeymapKey]];
	[middleClickCB setState: [defaults boolForKey: OXAutoMiddleClickKey]];
	
	[hcTopLeftCB setState: [defaults boolForKey: OXHotCornerTLKey]];
	[hcTopRightCB setState: [defaults boolForKey: OXHotCornerTRKey]];
	[hcBottomLeftCB setState: [defaults boolForKey: OXHotCornerBLKey]];
	[hcBottomRightCB setState: [defaults boolForKey: OXHotCornerBRKey]];
	
	[emulateButtonsCB setState: [defaults boolForKey: OXEmulateButtonsKey]];
	[disableScrollCB setState: [defaults boolForKey: OXDisableScrollKey]];
	
	// Find the index of the modifier key for middle and right emulation
	mod = [defaults integerForKey: OXMiddleModifierKey];
	for (i = 0; i < 5; i++)
		if (mod == modifierMap[i])
			break;
	if (i == 5)
		i = 0;
	//[middleButtonRB 
        
        for (i = 4; i >=0; i--)
	{
            NSDictionary* hostInfo;
            
            hostInfo = [defaults dictionaryForKey: (NSString*)OXHostNameKeyList[i]];
            
            if (hostInfo == nil)
                continue;
                        
            // Is this an auto connect thing?
            if ([[hostInfo objectForKey: OXConnectionReconnectKey] intValue])
            {
                [connectBag addConnectionToHost: [[NSString alloc] initWithString: [hostInfo objectForKey: OXConnectionNameKey]]
                                   withPosition: (XXWindowPos)[[hostInfo objectForKey: OXConnectionPosKey] intValue]
                                       withType: (XXConnectionType)[[hostInfo objectForKey: OXConnectionTypeKey] intValue]];
            }
    
	}

        [autoHostList setDataSource: connectBag];
        
    [defaults synchronize];
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)autoHostListSelect:(id)sender
{
    if ([(XXAutoConnectBag*)connectBag count] > 0)
    {
        [removeButton setEnabled: YES];
    }
    else
    {
        [removeButton setEnabled: NO];
    }
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)removeHost:(id)sender
{
    int row;
    NSString* name;
    XXWindowPos pos;
    XXConnectionType type;
    NSUserDefaults* defaults;
    int i;
    
    // Which host is connected?
    row = [autoHostList selectedRow];
    
    name = [connectBag getNameAtIndex: row];
    
    if (name == nil)
        return;
    
    pos = [connectBag getPositionAtIndex: row];
    type = [connectBag getTypeAtIndex: pos];
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Look for a match
    for (i = 4; i >=0; i--)
    {
        NSDictionary* hostInfo;
        NSMutableDictionary* newHostInfo;
        NSString* thisHost;
        XXWindowPos thisPos;
        XXConnectionType thisType;
        id objects[4];
	id keys[4];
        
        hostInfo = [defaults dictionaryForKey: (NSString*)OXHostNameKeyList[i]];
        
        if (hostInfo == nil)
            continue;
        
        thisHost = [hostInfo objectForKey: OXConnectionNameKey];
        thisPos = (XXWindowPos)[[hostInfo objectForKey: OXConnectionPosKey] intValue];
        thisType = (XXConnectionType)[[hostInfo objectForKey: OXConnectionTypeKey] intValue];
        
        // Match on ints first, as that's cheap
        if ((thisPos != pos) || (thisType != type))
            continue;
        
        // Match on host name?
        if ([thisHost compare: name] != NSOrderedSame)
            continue;
        
        // This is a match, so alter the ConnectionReconnnect to false            
	defaults = [NSUserDefaults standardUserDefaults];
	
	keys[0] = OXConnectionNameKey;
	keys[1] = OXConnectionTypeKey;
	keys[2] = OXConnectionPosKey;
	keys[3] = OXConnectionReconnectKey;
	
        objects[0] = name;
        objects[1] = [NSNumber numberWithInt: type];
        objects[2] = [NSNumber numberWithInt: pos];
        objects[3] = [NSNumber numberWithInt: FALSE];
            
        newHostInfo = [NSMutableDictionary dictionaryWithObjects: objects
                                                         forKeys: keys
                                                           count: 4];
        [defaults setObject: newHostInfo
                     forKey: (NSString*)OXHostNameKeyList[i]];
        
        // Updated the prefs - now just remove it from the table and
        // update the view
        [connectBag removeLine: i];
        [autoHostList reloadData];
        
        break;
    }
}


/*------------------------------------------------------------------------------
 *
 */
- (IBAction)valuesChanged:(id)sender
{
    NSUserDefaults *defaults;
	NSColor* colour;
	float red, green, blue;
	
    defaults = [NSUserDefaults standardUserDefaults];
	
    [defaults setBool: [hideWindowCB state]
			   forKey: OXHideWindowKey];
    [defaults setBool: [useKeychainCB state]
			   forKey: OXUseKeychainKey];
	[defaults setBool: [middleClickCB state]
			   forKey: OXAutoMiddleClickKey];
	
	[defaults setBool: [hcTopLeftCB state]
			   forKey: OXHotCornerTLKey];
	[defaults setBool: [hcTopRightCB state]
			   forKey: OXHotCornerTRKey];
	[defaults setBool: [hcBottomLeftCB state]
			   forKey: OXHotCornerBLKey];
	[defaults setBool: [hcBottomRightCB state]
			   forKey: OXHotCornerBRKey];
	[defaults setBool: [emulateButtonsCB state]
			   forKey: OXEmulateButtonsKey];
	
	[defaults setObject: [NSNumber numberWithFloat: [arrowTransSlider floatValue]]
				 forKey: OXArrowTransparencyKey];
		
	
	colour = [colorSelector color];
	
	[colour getRed: &red
			 green: &green
			  blue: &blue
			 alpha: NULL];
	
	[defaults setObject: [NSNumber numberWithFloat: red]
				 forKey: OXArrowColourRedKey];
	[defaults setObject: [NSNumber numberWithFloat: green]
				 forKey: OXArrowColourGreenKey];
	[defaults setObject: [NSNumber numberWithFloat: blue]
				 forKey: OXArrowColourBlueKey];
    [defaults setObject: [NSNumber numberWithInt: [mapList indexOfSelectedItem]]
				 forKey: OXDefaultKeymapKey];
    
    keymap_set([mapList indexOfSelectedItem]);

	
	
    if (xxController != nil)
        [xxController prefsChanged];
}

@end
