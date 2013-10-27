//
//  VideoStream.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "VideoStream.h"
#import <AVFoundation/AVFoundation.h>
AVCaptureSession * avSession = nil;

id getBackCamera(void)
{
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]) {
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device position] == AVCaptureDevicePositionBack)
            return device;
    }
    return nil;
}

@implementation VideoStream

+(void) init{
    if(avSession == nil)
    {
        avSession = [[AVCaptureSession alloc] init];
        AVCaptureDevice * device = getBackCamera();
        NSError * error = nil;
        AVCaptureDeviceInput * avVideoIn= [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        AVCaptureVideoDataOutput *  avVideoOut = [[AVCaptureVideoDataOutput alloc] init];
        if([avSession canAddInput: avVideoIn])
        {
            printf("av input success\n");
            [avSession addInput: avVideoIn];
        }
        else
        {
            fprintf(stderr, "av input failure\n");
        }
        if([avSession canAddOutput:avVideoOut])
        {
            printf("av output success\n");
            [avSession addOutput: avVideoOut];
        }
        else
        {
            fprintf(stderr, "av output failure\n");
        }
    }
}
@end
