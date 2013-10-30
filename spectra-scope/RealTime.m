//
//  RealTime.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 10/26/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added startCapture to set up capturing
 1.1: by Tian Lin Tan
 - added preview layer for displaying what the camera sees
 1.2: by Tian Lin Tan
 - added callback function for AVCaptureVideoDataOutput
 - added code to find display the colour of the center pixel
 1.3: by Tian Lin Tan
 - fixed bug where the queried pixel is not at the center, but at top center
 1.4: by Tian Lin Tan
 - added function to hide navigation bar when view is tapped
 1.5: by Tian Lin Tan
 - changed to cgimage for displaying frames
 - put viewdidload code to viewdidappear
 - put viewdidunload code to viewdiddisappear
 1.6: by Tian Lin Tan
 - added filters
 
 bugs:
 - (not a bug) viewDidunload is not called when user goes back one screen
 - (fixed)stopRunning isn't called, creating a new capture session every time the user moves to this screen
 - (fixe)empty bar below navigation bar, a wasted 20 rows of pixels
 - (fixed)empty bar below preview view, another wasted 20 rows of pixels
 */
#import "RealTime.h"
#import <AVFoundation/AVFoundation.h>
#import "colour_name.h"
enum filter_type{
    FL_NONE,
    FL_IBLUE,
    FL_IGREEN,
    FL_IRED,
    FL_NOBLUE,
    FL_NOGREEN,
    FL_NORED,
    FL_REDGREEN,
    FL_LAST
};
static NSString * filterNames[] ={
    [FL_NONE] = @"none",
    [FL_IBLUE] = @"invert blue",
    [FL_IGREEN] = @"invert green",
    [FL_IRED] = @"invert red",
    [FL_NOBLUE] = @"zero blue",
    [FL_NOGREEN] = @"zero green",
    [FL_NORED] = @"zero red",
    [FL_REDGREEN] = @"rg defficiency"
};
@interface RealTime ()
{
    BOOL hiddenBar;
    unsigned rAvg, gAvg, bAvg;
    enum filter_type filter;
}
@property(strong, nonatomic) AVCaptureSession * captureSession;

@property (weak, nonatomic) IBOutlet UILabel *bgrLabel;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;

@property(strong, nonatomic) CALayer * previewLayer;
@property (strong, nonatomic) IBOutlet UIControl *previewView;
@end

@implementation RealTime

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"initWithNibName");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        NSLog(@"init with coder");
        rAvg = 0;
        gAvg = 0;
        bAvg = 0;
        filter = FL_NONE;
        _captureSession = nil;
        _previewLayer = nil;
        _previewView = nil;
        _bgrLabel = nil;
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    hiddenBar = YES;
    [self.navigationController setNavigationBarHidden:hiddenBar animated:YES];
    [self startCapture];
    
}
// set up capture input and output, and start capturing
- (void) startCapture{
    if(_captureSession == nil)
    {
        NSLog(@"capture session setup");
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
        NSLog(@"capture session setup complete");
    }
    
    // add real time view
#if 0
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_captureSession];
    {
        CGRect box = _previewView.bounds;
        //box.origin.y += 20;
        //box.size.height += 40;
        _previewLayer.frame = box;
        _previewLayer.bounds = box;
        NSLog(@"%f, %f, %f, %f", box.origin.x, box.origin.y,
              box.size.width, box.size.height);
    }
    [_previewView.layer addSublayer:_previewLayer];
    [_previewLayer addSublayer: _bgrLabel.layer];
#else
    if(_previewLayer == nil)
    {
        NSLog(@"preview layer setup");
        _previewLayer = [[CALayer alloc] init];
        _previewLayer.frame = _previewView.bounds;
        _previewLayer.bounds = _previewView.bounds;
        _previewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI_2);
        _previewLayer.contentsGravity = kCAGravityResizeAspectFill;
        [_previewView.layer addSublayer: _previewLayer];
        [_previewView.layer addSublayer:_bgrLabel.layer];
        [_previewView.layer addSublayer:_filterButton.layer];
        NSLog(@"preview layer setup complete");
    }
#endif
    // start capturing
    [_captureSession startRunning];
    NSLog(@"started capturing");
    
}

/* delegate for accessing pixel buffers of frames.
 this is where the image processing happens*/
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {

        CVImageBufferRef pixelBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        CVPixelBufferLockBaseAddress(pixelBuf,0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuf);
        unsigned bpr = CVPixelBufferGetBytesPerRow(pixelBuf);
        unsigned width = CVPixelBufferGetWidth(pixelBuf);
        unsigned height = CVPixelBufferGetHeight(pixelBuf);
        unsigned center = height / 2 * bpr + bpr / 2;
        
        unsigned b = baseAddress[center];
        unsigned g = baseAddress[center + 1];
        unsigned r = baseAddress[center + 2];
        
        rAvg = (rAvg * 7 + r) / 8;
        gAvg = (gAvg * 7 + g) / 8;
        bAvg = (bAvg * 7 + b) / 8;
        
        //NSLog(@"base:%p, center:%d", baseAddress, center);
        switch(filter)
        {
            case FL_IBLUE:
            case FL_IGREEN:
            case FL_IRED:
                for(unsigned i = filter - FL_IBLUE, end = height * bpr; i < end; i += 4)
                {
                    baseAddress[i] += 127;
                }
                break;
            case FL_NOBLUE:
            case FL_NOGREEN:
            case FL_NORED:
                for(unsigned i = filter - FL_NOBLUE, end = height * bpr; i < end; i+=4)
                {
                    baseAddress[i] = 0;
                }
                break;
            case FL_REDGREEN:
                for(unsigned i = 0, end = height * bpr; i < end; i += 4)
                {
                    unsigned rgavg = baseAddress[i + 1] + baseAddress[i + 2];
                    rgavg /= 2;
                    baseAddress[i + 1] = rgavg;
                    baseAddress[i + 2] = rgavg;
                }
                break;
            default:
                break;
        }
        char const * name = colour_string(colour_name(r, g, b));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bpr, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef dstImage = CGBitmapContextCreateImage(context);
        dispatch_sync(dispatch_get_main_queue(), ^{
            _bgrLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d name:%s", rAvg, gAvg, bAvg, name];
            _previewLayer.contents = (__bridge id)(dstImage);
            CGImageRelease(dstImage);
        });
        
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(pixelBuf,0);
    }
    
}

// toggle the hiding of the navigation bar
-(IBAction)touchedView:(id)sender{
    hiddenBar = !hiddenBar;
    [self.navigationController setNavigationBarHidden:hiddenBar animated:YES];
}
-(IBAction)touchedFilterButton:(id)sender{
    filter = (filter + 1) % FL_LAST;
    [_filterButton setTitle:filterNames[filter] forState:UIControlStateNormal];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    
    [self setFilterButton:nil];
    [super viewDidUnload];
}
-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_captureSession stopRunning];
    NSLog(@"stopped capturing");
}
@end
