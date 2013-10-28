//
//  RealTime.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "RealTime.h"
#import <AVFoundation/AVFoundation.h>
#import "colour_name.h"

@interface RealTime ()
{
    BOOL hiddenBar;
}
@property(strong, nonatomic) AVCaptureSession * captureSession;

@property (weak, nonatomic) IBOutlet UILabel *bgrLabel;

@property(strong, nonatomic) AVCaptureVideoPreviewLayer * previewLayer;
@property (strong, nonatomic) IBOutlet UIControl *previewView;
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
    hiddenBar = NO;
    [self startCapture];
}

- (void) startCapture{
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // add input stream
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError * error = nil;
    AVCaptureDeviceInput * avVideoIn= [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if([_captureSession canAddInput: avVideoIn])
    {
        NSLog(@"%@",[avVideoIn description]);
        [_captureSession addInput: avVideoIn];
    }
    else
    {
        NSLog(@"%@", @"unable to open input device");
        return;
    }
    
    // add output stream
    AVCaptureVideoDataOutput *  avVideoOut = [[AVCaptureVideoDataOutput alloc] init];
    avVideoOut.alwaysDiscardsLateVideoFrames = YES;
    avVideoOut.videoSettings = [NSDictionary dictionaryWithObject:
                                [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                           forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [avVideoOut setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    if([_captureSession canAddOutput:avVideoOut])
    {
        NSLog(@"%@", [avVideoOut description]);
        [_captureSession addOutput: avVideoOut];
    }
    else
    {
        NSLog(@"%@", @"unable to create video output");
        return;
    }
    
    // add real time view
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    {
        CGRect box = _previewView.bounds;
        //box.origin.y += 20;
        box.size.height -= 10;
        _previewLayer.frame = box;
        NSLog(@"%f, %f, %f, %f", box.origin.x, box.origin.y,
              box.size.width, box.size.height);
    }
    [_previewView.layer addSublayer:_previewLayer];
    [_previewLayer addSublayer: _bgrLabel.layer];
    
    // start capturing
    [_captureSession startRunning];
    NSLog(@"started capturing");
    
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {

        CVImageBufferRef pixelBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CVPixelBufferLockBaseAddress(pixelBuf,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuf);
        unsigned bpr = CVPixelBufferGetBytesPerRow(pixelBuf);
        //unsigned width = CVPixelBufferGetWidth(pixelBuf);
        unsigned height = CVPixelBufferGetHeight(pixelBuf);
        unsigned center = height / 2 * bpr + bpr / 2;
        
        uint8_t b = baseAddress[center];
        uint8_t g = baseAddress[center + 1];
        uint8_t r = baseAddress[center + 2];
        
        //NSLog(@"base:%p, center:%d", baseAddress, center);
    
        char const * name = colour_string(colour_name(r, g, b));
        dispatch_sync(dispatch_get_main_queue(), ^{
            _bgrLabel.text = [NSString stringWithFormat:@"r:%02x g:%02x b:%02x\n%s", r, g, b, name];
        });

        CVPixelBufferUnlockBaseAddress(pixelBuf,0);
    }
    
}
-(IBAction)touchedView:(id)sender{
    hiddenBar = !hiddenBar;
    [self.navigationController setNavigationBarHidden:hiddenBar animated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [_captureSession stopRunning];
    NSLog(@"stopped capturing");
    [super viewDidUnload];
}
@end
