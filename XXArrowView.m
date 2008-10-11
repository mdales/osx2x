//
// XXArrowView.m
// osx2x
//
// Copyright (c) Michael Dales 2004
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
#import "XXArrowView.h"


#define SetPoint(_p,_x,_y) _p.x = _x; _p.y = _y

@implementation XXArrowView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) 
    {
		direction = XXWindowEast; // just a random default
    }
    return self;
}

- (void)dealloc
{
    [outline release];
	[arrowColour release];
    [super dealloc];
}

- (id)initWithFrame: (NSRect)frame
      withDirection: (XXWindowPos)dir
{
	NSPoint p;
	//NSAffineTransform *trans = [NSAffineTransform transform];  
	NSAffineTransform *scale, *rotate, *translate;
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float red, green, blue;
	
	scale = [NSAffineTransform transform];
	rotate = [NSAffineTransform transform];
	translate = [NSAffineTransform transform];
	
    self = [self initWithFrame: frame];
    
	if (self == nil)
		return nil;
	
    direction = dir;
	
	// setup the arrow outline
	outline = [[NSBezierPath alloc] init];
	[outline setLineWidth: 4.0];
	
	[outline setLineCapStyle: NSRoundLineCapStyle];
	
	SetPoint(p, 0.5, 1.0);
	[outline moveToPoint: p];
	SetPoint(p, 0.5, 2.0);
	[outline lineToPoint: p];
	SetPoint(p, 1.5, 2.0);
	[outline lineToPoint: p];
	SetPoint(p, 1.5, 3.0);
	[outline lineToPoint: p];
	SetPoint(p, 3.0, 1.5);
	[outline lineToPoint: p];
	SetPoint(p, 1.5, 0.0);
	[outline lineToPoint: p];
	SetPoint(p, 1.5, 1.0);
	[outline lineToPoint: p];
	[outline closePath];
	
	
	// Now, do we wish to rotate it according to the direction?
	switch (direction)
	{
		case XXWindowNorth:
			[translate translateXBy: 3.0
								yBy: 0.0];
			[rotate rotateByDegrees: 90.0];
			break;
		case XXWindowWest:
			[translate translateXBy: 3.0
								yBy: 3.0];
			[rotate rotateByDegrees: 180.0];
			break;
		case XXWindowSouth:
			[translate translateXBy: 0.0
								yBy: 3.0];
			[rotate rotateByDegrees: 270.0];
			break;
		default:
			break;
	}

	// Step one is to scale the little arrow to fit. The arrow is currently
	// 3 units high, and 2.5 units across.
	[scale scaleXBy: frame.size.width / 3.0
				yBy: frame.size.height / 3.0];

	// Apply the transformation we've created
	[outline transformUsingAffineTransform: rotate];
	[outline transformUsingAffineTransform: translate];
	[outline transformUsingAffineTransform: scale];
	
	//arrowColour = [defaults objectForKey: OXArrowColourKey];
	
	red = [defaults floatForKey: OXArrowColourRedKey];
	green = [defaults floatForKey: OXArrowColourGreenKey];
	blue = [defaults floatForKey: OXArrowColourBlueKey];
	arrowColour = [NSColor colorWithCalibratedRed: red
									   green: green
										blue: blue
									   alpha: 1.0];
	[arrowColour retain];
		
    return self;
}


- (void)updateColour
{
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
	float red, green, blue;

	[arrowColour release];
	red = [defaults floatForKey: OXArrowColourRedKey];
	green = [defaults floatForKey: OXArrowColourGreenKey];
	blue = [defaults floatForKey: OXArrowColourBlueKey];
	arrowColour = [NSColor colorWithCalibratedRed: red
											green: green
											 blue: blue
											alpha: 1.0];
	[arrowColour retain];

	[self setNeedsDisplay: TRUE];
}


- (void)drawRect:(NSRect)rect 
{  
    [arrowColour set];
    [outline fill];
    
    [[NSColor blackColor] set];
    [outline stroke];
}

@end
