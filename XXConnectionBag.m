//
//  XXConnectionBag.m
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

#import "XXConnectionBag.h"


@implementation XXConnectionBag

- init
{
    if ((self = [super init]) != nil)
    {
        int i;

        for (i = 0; i < 5; i++)
            bag[i] = nil;

        size = 0;
    }

    return self;
}

- (void)addConnection: (XXConnection*)connection
{
    XXWindowPos pos;
    
    // first see if we have a connection in that position, if not, don't allow it
    pos = [connection getPosition];

    if (bag[pos] != nil)
    {
        NSException* myException = [NSException exceptionWithName: @"InsertionFailed"
                                                           reason: @"Duplicate Entry"
                                                         userInfo: nil];
        [myException raise];
    }

    bag[pos] = connection;
    size += 1;        
}

- (void)removeConnection: (XXConnection*)connection
{
    int i;
    NSException* myException;

    for (i = 0; i < 5; i++)
    {
        if (bag[i] == connection)
        {
            NSLog(@"Removing connection\n");
            
            size -= 1;
            bag[i] = nil;
            
            return;
        }
    }

    myException = [NSException exceptionWithName: @"RemoveFailed"
                                          reason: @"Invalid Entry"
                                        userInfo: nil];
    [myException raise];
}

- (void)removeFromPosition: (XXWindowPos)position
{
    NSException* myException;


    if (bag[position] != nil)
    {
        size -= 1;
        bag[position] = nil;

        return;
    }

    myException = [NSException exceptionWithName: @"RemoveFailed"
                                          reason: @"Invalid Entry"
                                        userInfo: nil];
    [myException raise];
}


- (XXConnection*)getFromPosition: (XXWindowPos)position;
{
    if (position < 5)
        return bag[position];
    else
        return nil;
}


- (XXConnection*)getFromTableRow: (int)row
{
    int i, j;
    XXConnection* connection = nil;
    
    // get the "rowIndex"th entry
    for (i = 0, j = -1; i < 5; i++)
    {
        if (bag[i] != nil)
        {
            j++;
            if (j == row)
            {
                connection = bag[i];
                break;
            }
        }
    }

    return connection;
}

- (int)count
{
    return size;
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return size;
}


- (id)tableView: (NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    NSUserDefaults *defaults;
    int column, i, j;
    id temp;
    XXConnection* connection;

    temp = [aTableColumn identifier];
    column = [temp intValue];
    defaults = [NSUserDefaults standardUserDefaults];

    // get the "rowIndex"th entry
    for (i = 0, j = -1; i < 5; i++)
    {
        if (bag[i] != nil)
        {
            j++;
            if (j == rowIndex)
            {
                connection = bag[i];
                break;
            }
        }
    }

    if (connection != nil)
    {
        switch (column)
        {
            case 1:
                return [connection getHostName];
                break;
            case 2:
                return [connection getPositionName];
                break;
            case 3:
                return [connection getConnectionName];
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
