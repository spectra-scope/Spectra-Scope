//
//  RealTime.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "RealTime.h"

id getBackCamera(void)
{
    for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType: AVMediaTypeVideo]) {
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device position] == AVCaptureDevicePositionBack)
            return device;
    }
    return nil;
}
@interface RealTime ()
@property(strong, nonatomic) AVCaptureSession * captureSession;
@property(strong, nonatomic) CALayer * customLayer;
@property(strong, nonatomic) AVCaptureVideoPreviewLayer * prevLayer;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
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
    if(_captureSession == nil)
    {
        _captureSession = [[AVCaptureSession alloc] init];
        AVCaptureDevice * device = getBackCamera();
        NSError * error = nil;
        AVCaptureDeviceInput * avVideoIn= [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        
        AVCaptureVideoDataOutput *  avVideoOut = [[AVCaptureVideoDataOutput alloc] init];
        
        avVideoOut.alwaysDiscardsLateVideoFrames = YES;
        
        dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
        [avVideoOut setSampleBufferDelegate:self queue:queue];
        dispatch_release(queue);
        if([_captureSession canAddInput: avVideoIn])
        {
            printf("av input success\n");
            [_captureSession addInput: avVideoIn];
        }
        else
        {
            fprintf(stderr, "av input failure\n");
            return;
        }
        if([_captureSession canAddOutput:avVideoOut])
        {
            printf("av output success\n");
            [_captureSession addOutput: avVideoOut];
        }
        else
        {
            fprintf(stderr, "av output failure\n");
            return;
        }
    }
	// Do any additional setup after loading the view.
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        
        /*We display the result on the custom layer. All the display stuff must be done in the main thread because
         UIKit is no thread safe, and as we are not in the main thread (remember we didn't use the main_queue)
         we use performSelectorOnMainThread to call our CALayer and tell it to display the CGImage.*/
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.customLayer setContents:(__bridge id)newImage];
        });
        
        /*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly).
         Same thing as for the CALayer we are not in the main thread so ...*/
        UIImage *image= [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
        
        /*We relase the CGImageRef*/
        CGImageRelease(newImage);
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [_imageView setImage:image];
        });
        
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    }
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidUnload {
    [self setImageView:nil];
    [super viewDidUnload];
}
@end
