//
//  SpeechSynthesis.h
//  spectra-scope
//
//  Created by tt on 13-11-09.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpeechSynthesis : NSObject
/* initializes module if not already initialized*/
+(void)initSingleton;

/* say a word. This is a blocking function.*/
+(void)say:(NSString*)word;
@end
