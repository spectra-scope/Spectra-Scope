//
//  ColourAlgorithmTest.m
//  spectra-scope
//
//  Created by tt on 13-10-28.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added colour test
 
 */
#import "ColourAlgorithmTest.h"
#import "colour_name.h"
@interface Colour :NSObject
{
    uint8_t r, g, b;
}
@end
@implementation Colour
-(id) initR:(unsigned)R G:(unsigned)G B:(unsigned)B{
    self = [super init];
    r = R;
    g = G;
    b = B;
    return self;
}
-(uint8_t) r{
    return r;
}
-(uint8_t) g{
    return g;
}
-(uint8_t) b{
    return b;
}

@end
@interface ColourAlgorithmTest ()
{
    NSDictionary * colourPairs;
}
@end

@implementation ColourAlgorithmTest

/* set up a list of pairs of colours and colour names,
and test if the colour name algo have the same "opinion"
 as I do.
 */
-(void) setUp{
    [super setUp];
    colourPairs = @{[[NSNumber alloc] initWithInt:BLACK]    : [[Colour alloc] initR:0 G:0 B:0],
                    [[NSNumber alloc] initWithInt:WHITE]    : [[Colour alloc] initR:250 G:250 B:250],
                    [[NSNumber alloc] initWithInt:GREY]     : [[Colour alloc] initR:100 G:100 B:100],
                    [[NSNumber alloc] initWithInt:RED]      : [[Colour alloc] initR:100 G:0 B:0],
                    [[NSNumber alloc] initWithInt:GREEN]    : [[Colour alloc] initR:0 G:100 B:0],
                    [[NSNumber alloc] initWithInt:BLUE]     : [[Colour alloc] initR:0 G:0 B:100],
                    [[NSNumber alloc] initWithInt:YELLOW]   : [[Colour alloc] initR:100 G:100 B:0],
                    [[NSNumber alloc] initWithInt:CYAN]     : [[Colour alloc] initR:0 G:100 B:100],
                    [[NSNumber alloc] initWithInt:MAGENTA]  : [[Colour alloc] initR:100 G:0 B:100]
                    };
    
}
-(void) testeColourName{
    for(NSNumber * name in colourPairs)
    {
        enum colour nameID = [name intValue];
        Colour * colour = [colourPairs objectForKey: name];
        uint8_t r = [colour r], g = [colour g], b = [colour b];
        if(nameID != colour_name(r, g, b))
            STFail(@"colour name identification failed for basic colour %s", colour_string(nameID));
    }
}
@end
