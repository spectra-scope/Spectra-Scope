//
//  RealTime.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - class now conforms to AVCaptureVideoDataOutputSampleBufferDelegate
 */
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface RealTime : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@end
