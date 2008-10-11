//
//  AutoConnectBag.h
//  osx2x
//
//  Created by Michael Dales on Tue Jun 29 2004.
//  Copyright (c) 2004 Michael Dales. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XXController.h"

@interface XXAutoConnectBag : NSObject {
    int size;
    
    NSString* names[5];
    XXConnectionType types[5];
    XXWindowPos positions[5];
}
- (void)addConnectionToHost: (NSString*)name
               withPosition: (XXWindowPos)pos
                   withType: (XXConnectionType)type;
- (NSString*)getNameAtIndex: (int)index;
- (XXWindowPos)getPositionAtIndex: (int)index;
- (XXConnectionType)getTypeAtIndex: (int)index;
- (int)count;
- (void)removeLine: (int)index;
@end
