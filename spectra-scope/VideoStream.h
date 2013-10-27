//
//  VideoStream.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
extern AVCaptureSession * avSession;
@interface VideoStream : NSObject
+(void)init;
@end
