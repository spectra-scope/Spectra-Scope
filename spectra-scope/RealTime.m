//
//  RealTime.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "RealTime.h"
#import <AVFoundation/AVFoundation.h>

@interface RealTime ()
@property(strong, nonatomic) AVCaptureSession * captureSession;

@property (weak, nonatomic) IBOutlet UILabel *bgrLabel;

@property(strong, nonatomic) AVCaptureVideoPreviewLayer * previewLayer;
@property (strong, nonatomic) IBOutlet UIView *previewView;
@end

@implementation RealTime

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError * error = nil;
    AVCaptureDeviceInput * avVideoIn= [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    
    AVCaptureVideoDataOutput *  avVideoOut = [[AVCaptureVideoDataOutput alloc] init];
    avVideoOut.alwaysDiscardsLateVideoFrames = YES;
    avVideoOut.videoSettings = [NSDictionary dictionaryWithObject:
                                [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                           forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [avVideoOut setSampleBufferDelegate:self queue:queue];

    if([_captureSession canAddInput: avVideoIn])
    {
        NSLog(@"%@",[avVideoIn description]);
        [_captureSession addInput: avVideoIn];
    }
    if([_captureSession canAddOutput:avVideoOut])
    {
        NSLog(@"%@", [avVideoOut description]);
        [_captureSession addOutput: avVideoOut];
    }
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    _previewLayer.frame = _previewView.frame;
    [_previewView.layer addSublayer:_previewLayer];
    
    [_captureSession startRunning];
    NSLog(@"start running");
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        NSLog(@"hello");

        CVImageBufferRef pixelBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CVPixelBufferLockBaseAddress(pixelBuf,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuf);
        unsigned bpr = CVPixelBufferGetBytesPerRow(pixelBuf);
        unsigned width = CVPixelBufferGetWidth(pixelBuf);
        unsigned height = CVPixelBufferGetHeight(pixelBuf);
        
        uint8_t b = baseAddress[width * height * bpr / 2];
        uint8_t g = baseAddress[width * height * bpr / 2 + 1];
        uint8_t r = baseAddress[width * height * bpr / 2 + 2];
        char bgr[20];
        snprintf(bgr, sizeof bgr, "b:%x g:%x r:%x", b, g, r);
        NSString * bgrLabelText = [[NSString alloc] initWithUTF8String:bgr];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
           
            _bgrLabel.text = bgrLabelText;
        });
        

        CVPixelBufferUnlockBaseAddress(pixelBuf,0);
    }
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [_captureSession stopRunning];
    [super viewDidUnload];
}
@end
