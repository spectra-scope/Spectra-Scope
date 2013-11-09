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
#import <Slt/Slt.h>
#import <OpenEars/FliteController.h>
#import  <OpenEars/LanguageModelGenerator.h>
#import <OpenEars/PocketsphinxController.h>
#import <OpenEars/AcousticModel.h>
#import <OpenEars/OpenEarsEventsObserver.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "GPUImage.h"
@interface RealTimeModeViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate, GPUImageVideoCameraDelegate>
{
    FliteController *fliteController;
    Slt *slt;
}

@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;

@end
