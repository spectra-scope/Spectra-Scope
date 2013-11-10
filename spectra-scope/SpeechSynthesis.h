//
//  SpeechSynthesis.h
//  spectra-scope
//
//  Created by tt on 13-11-09.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpeechSynthesis : NSObject
+(void)initSingleton;
+(void)say:(NSString*)word;
@end
