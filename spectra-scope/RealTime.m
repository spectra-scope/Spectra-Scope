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
#define USE_GPUIMAGE
#import "RealTime.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>

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
    CIContext * context;
    CIFilter * cifilter;
    
    GPUImageVideoCamera * gpuCamera;
    GPUImageView * gpuView;
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
        context = nil;
        cifilter = nil;
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
// toggle the hiding of the navigation bar
-(IBAction)touchedView:(id)sender{
    hiddenBar = !hiddenBar;
    [self.navigationController setNavigationBarHidden:hiddenBar animated:YES];
}
-(IBAction)touchedFilterButton:(id)sender{
    filter = (filter + 1) % FL_LAST;
    [_filterButton setTitle:filterNames[filter] forState:UIControlStateNormal];
#ifdef USE_GPUIMAGE
    [gpuCamera removeAllTargets];
#endif
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setFilterButton:nil];
#ifdef USE_GPUIMAGE
    gpuView = nil;
    gpuCamera = nil;
#endif
    [super viewDidUnload];
}
-(void)viewDidDisappear:(BOOL)animated{
    
#ifdef USE_GPUIMAGE
    [gpuCamera stopCameraCapture];
#else
    [_captureSession stopRunning];
#endif
    NSLog(@"stopped capturing");
    [super viewDidDisappear:animated];
}

/* startCapture is the final setup step to perform before the screen can display what the camera captures.*/
#ifdef USE_GPUIMAGE
-(void) startCapture{
    NSLog(@"GPUImage capture setup");
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    
    gpuCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetMedium cameraPosition:AVCaptureDevicePositionBack];
    gpuCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    gpuView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
    [self.view addSubview:gpuView];
    
    GPUImageColorMatrixFilter * filter3 = [[GPUImageColorMatrixFilter alloc] init];

    GPUMatrix4x4 mat = {
        {0.5, 0.5, 0, 0},
        {0.5, 0.5, 0, 0},
        {0, 0, 1, 0},
        {0, 0, 0, 1}
    };
    [filter3 setColorMatrix:mat];
    [filter3 forceProcessingAtSize:gpuView.sizeInPixels];
    
    [filter3 addTarget:gpuView];
    [gpuCamera addTarget:filter3];
    
    gpuCamera.delegate = self;
    
    [gpuView addSubview:_filterButton];
    
    [gpuCamera startCameraCapture];
    NSLog(@"GPUImage capture setup complete");
    NSLog(@"delegate is %p", gpuCamera.delegate);
}
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CVImageBufferRef pixelBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
   
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuf);
    CVPixelBufferLockBaseAddress(pixelBuf, kCVPixelBufferLock_ReadOnly);
    {
        unsigned b, g, r;        
        if(format == kCVPixelFormatType_32BGRA)
        {
            uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuf);
            unsigned bpr = CVPixelBufferGetBytesPerRow(pixelBuf);
            unsigned width = CVPixelBufferGetWidth(pixelBuf);
            unsigned height = CVPixelBufferGetHeight(pixelBuf);
            unsigned center = height / 2 * bpr + bpr / 2;
            
            b = baseAddress[center];
            g = baseAddress[center + 1];
            r = baseAddress[center + 2];
        }
        else if(format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        {
            /* for reference:
             http://stackoverflow.com/questions/13429456/how-seperate-y-planar-u-planar-and-uv-planar-from-yuv-bi-planar-in-ios
             */
            signed y, u, v;
            {
                uint8_t * lumaAddr = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 0);
                unsigned bpr = CVPixelBufferGetBytesPerRowOfPlane(pixelBuf, 0);
                unsigned height = CVPixelBufferGetHeightOfPlane(pixelBuf, 0);
                unsigned lumaCenter = height / 2 * bpr + bpr / 2;
                y = lumaAddr[lumaCenter];
            }
            {
                uint8_t * cbcrAddr = CVPixelBufferGetBaseAddressOfPlane(pixelBuf, 1);
                unsigned bpr = CVPixelBufferGetBytesPerRowOfPlane(pixelBuf, 1);
                unsigned height = CVPixelBufferGetHeightOfPlane(pixelBuf, 1);
                unsigned uvCenter = height / 2 * bpr + bpr / 2;
                u = cbcrAddr[uvCenter];
                v = cbcrAddr[uvCenter + 1];
            }
            
            /* for reference:
             http://msdn.microsoft.com/en-us/library/aa917087.aspx
             */
            {
                signed c = y - 16;
                signed d = u - 128;
                signed e = v - 128;
                
#define clip(lo, hi, n) (n < lo ? lo : n > hi ? hi : n)
                r = clip(0, 255, (( 298 * c           + 409 * e + 128) >> 8));
                g = clip(0, 255, (( 298 * c - 100 * d - 208 * e + 128) >> 8));
                b = clip(0, 255, (( 298 * c + 516 * d           + 128) >> 8));
#undef clip
            }
        }
        else
        {
            NSLog(@"pixel format not supported");
            b=g=r=0;
        }
        rAvg = (rAvg * 7 + r) / 8;
        gAvg = (gAvg * 7 + g) / 8;
        bAvg = (bAvg * 7 + b) / 8;
        char const * name = colour_string(colour_name(r, g, b));
        dispatch_sync(dispatch_get_main_queue(), ^{
            _bgrLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d name:%s", rAvg, gAvg, bAvg, name];
        });
    }
    CVPixelBufferUnlockBaseAddress(pixelBuf,kCVPixelBufferLock_ReadOnly);
}
#else
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
#if 1
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
                    baseAddress[i] = 255 - baseAddress[i];
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
#else
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
        CVPixelBufferUnlockBaseAddress(pixelBuf,0);
        rAvg = (rAvg * 7 + r) / 8;
        gAvg = (gAvg * 7 + g) / 8;
        bAvg = (bAvg * 7 + b) / 8;
        
        //NSLog(@"base:%p, center:%d", baseAddress, center);

        char const * name = colour_string(colour_name(r, g, b));

        if(context == nil)
        {
            context = [CIContext contextWithOptions:nil];
        }
        CIImage *dstImage = [CIImage imageWithCVPixelBuffer:pixelBuf];
        if(cifilter == nil)
        {
            cifilter = [CIFilter filterWithName:@"CIColorMatrix"]; // 2
            [cifilter setDefaults]; // 3
            [cifilter setValue:dstImage forKey:kCIInputImageKey]; // 4
            [cifilter setValue:[CIVector vectorWithX:0.5 Y:0.5 Z:0 W:0] forKey:@"inputRVector"]; // 5
            [cifilter setValue:[CIVector vectorWithX:0.5 Y:0.5 Z:0 W:0] forKey:@"inputGVector"]; // 6
            [cifilter setValue:[CIVector vectorWithX:0 Y:0 Z:1 W:0] forKey:@"inputBVector"]; // 7
            [cifilter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:1] forKey:@"inputAVector"]; // 8
        }
        
        dstImage = [cifilter outputImage];
        CGImageRef cgimg = [context createCGImage:dstImage fromRect:[dstImage extent]];
        dispatch_sync(dispatch_get_main_queue(), ^{
            _bgrLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d name:%s", rAvg, gAvg, bAvg, name];
            _previewLayer.contents = (__bridge id)(cgimg);
            CGImageRelease(cgimg);
        });
        
        
#endif
    }
    
}
#endif


@end
