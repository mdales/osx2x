//
//  AutoConnectBag.m
//  osx2x
//
//  Created by Michael Dales on Tue Jun 29 2004.
//  Copyright (c) 2004 Michael Dales. All rights reserved.
//

#import "XXAutoConnectBag.h"


#define NONE NSLocalizedStringFromTable(@"None", @"osx2x", "Connection direction")
#define EAST NSLocalizedStringFromTable(@"East", @"osx2x", "Connection direction")
#define WEST NSLocalizedStringFromTable(@"West", @"osx2x", "Connection direction")
#define NORTH NSLocalizedStringFromTable(@"North", @"osx2x", "Connection direction")
#define SOUTH NSLocalizedStringFromTable(@"South", @"osx2x", "Connection direction")

static const NSString* connectionNames[3] = {@"X11", @"VNC", @"Daemon"};
static NSString* positionNames[5];  

@implementation XXAutoConnectBag

- init
{
    if ((self = [super init]) != nil)
    {
        int i;
        
        size = 0;
        
        for (i = 0; i < 5; i++)
        {
            names[i] = nil;
        }
        
        positionNames[0] = NONE;
        positionNames[1] = EAST;
        positionNames[2] = WEST;
        positionNames[3] = NORTH;
        positionNames[4] = SOUTH;
    }
    
    return self;
}

- (void)dealloc
{
    int i;
    
    for (i = 0; i < 5; i++)
        if (names[i] != nil)
            [names[i] release];
    
    [super dealloc];
}

- (int)count
{
    return size;
}

- (void)addConnectionToHost: (NSString*)name
               withPosition: (XXWindowPos)pos
                   withType: (XXConnectionType)type
{
    if (size >= 5)
        return; // Erm, this shouldn't happen...

    names[size] = name;
    types[size] = type;
    positions[size] = pos;
    size++;
}

- (void)removeLine: (int)index
{
    int i;
    
    if ((index < 0) || (index >= 5))
        return;
    if (names[index] == nil)
        return;
    
    // Move everything up
    for (i = index; i < 4; i++)
    {
        names[i] = names[i+1];
        positions[i] = positions[i+1];
        types[i] = types[i+1];
    }
    names[4] = nil;  // whichever line we delete, the last one will
                     // end up blank.
    
    size--;
}

- (NSString*)getNameAtIndex: (int)index
{
    if ((index < 0) || (index >= 5))
        return nil;
    
    return names[index];
}

- (XXWindowPos)getPositionAtIndex: (int)index
{
    if ((index < 0) || (index >= 5))
        return -1;
    
    return (names[index] == nil) ? -1 : positions[index];
}

- (XXConnectionType)getTypeAtIndex: (int)index
{
    if ((index < 0) || (index >= 5))
        return -1;
    
    return (names[index] == nil) ? -1 : types[index];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return size;
}


- (id)tableView: (NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    int column;
    id temp;
    
    temp = [aTableColumn identifier];
    column = [temp intValue];
    
    //NSLog(@"rowIndex = %d column = %d names = %p\n", rowIndex, column, names[rowIndex]);
    
    if (names[rowIndex] != nil)
    {
        switch (column)
        {
            case 1:
                return names[rowIndex];
                break;
            case 2:
                return positionNames[positions[rowIndex]];
                break;
            case 3:
                return (id)connectionNames[(int)types[rowIndex]];
                break;
        }
    }
    
    return nil;
}


- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex
{
}

@end
