//
//  SpeechSynthesis.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-09.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "SpeechSynthesis.h"

#import "Slt/Slt.h"
#import "OpenEars/FliteController.h"
#import "OpenEars/LanguageModelGenerator.h"
#import "OpenEars/PocketsphinxController.h"
#import "OpenEars/AcousticModel.h"
#import "OpenEars/OpenEarsEventsObserver.h"

static Slt * slt = nil;
static FliteController * fliteController = nil;

@implementation SpeechSynthesis
+(void)initSingleton{
    if(slt == nil)
        slt = [[Slt alloc] init];
    if(fliteController == nil)
        fliteController = [[FliteController alloc] init];
}
+(void) say:(NSString*)word{
    if(fliteController != nil && slt != nil)
    {
        [fliteController say:word withVoice:slt];
    }
    else
    {
        NSLog(@"speech synthesis not initialied");
    }
}

@end
