//
//  RealTimeModeViewController.m
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
 1.7: by Tian Lin Tan
 - added library GPUImage, for real time filtering
 1.8: by Archit Sood
 - Added Text to Speech Functionality in real time mode
 - Open Ears Library Used
 1.9: by Tian Lin Tan
 - added more detailed colour information
 - fixed colour information to moving average
 - displays warning message if run on simulator
 
 bugs (iteration 1):
 - (not a bug) viewDidunload is not called when user goes back one screen
 - (fixed)stopRunning isn't called, creating a new capture session every time the user moves to this screen
 - (fixed)empty bar below navigation bar, a wasted 20 rows of pixels
 - (fixed)empty bar below preview view, another wasted 20 rows of pixels
 bugs (iteration 2):
 - (fixed)viewDidUnload is never called, but viewDidload is called every time this screen is entered
 - (fixed) changing filters  would randmoly make the program abort
 */
#define USE_GPUIMAGE
#import "RealTimeModeViewController.h"
#import "colour_name.h"
#import "Filters.h"
#import "matrix.h"
#import "SpeechSynthesis.h"



@interface RealTimeModeViewController ()
{
    unsigned rAvg, gAvg, bAvg;
    unsigned counter;
    GPUImageVideoCamera * gpuCamera;
    GPUImageView * gpuView;
    GPUImageColorMatrixFilter * gpuFilter;
    struct mat4x4 colorMatrix;
    dispatch_queue_t soundQueue;
}

//colour info label
@property (weak, nonatomic) IBOutlet UILabel *bgrLabel;

//aiming reticule
@property (weak, nonatomic) IBOutlet UIImageView *reticuleImage;

//filter ui
@property (weak, nonatomic) IBOutlet UIView *filterListView;
@property (weak, nonatomic) IBOutlet UIButton *rgdFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *markGreenFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *markRedFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *clearFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *brightenGreenButton;
@property (weak, nonatomic) IBOutlet UIButton *brightenRedButton;

//function ui
@property (weak, nonatomic) IBOutlet UIView *buttonGroup;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@end
@implementation RealTimeModeViewController
#pragma mark - view controller
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
    }
    return self;
}
- (void)viewDidLoad
{
     NSLog(@"real time view did load");
    [super viewDidLoad];
    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    gpuView = [[GPUImageView alloc] initWithFrame:CGRectOffset(mainScreenFrame, 0, -20)];
    self.view = gpuView;
    [gpuView addSubview:_bgrLabel];
    [gpuView addSubview:_reticuleImage];
    [gpuView addSubview:_filterListView];
    [gpuView addSubview:_buttonGroup];
    _reticuleImage.center = gpuView.center;
    NSLog(@"GPUImage view setup complete");
    
    gpuCamera = [[GPUImageVideoCamera alloc]
                 initWithSessionPreset:AVCaptureSessionPresetMedium
                 cameraPosition:AVCaptureDevicePositionBack
                 usingYUV:NO];
    gpuCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    NSLog(@"GPUImage camera setup complete");
    
    gpuFilter = [[GPUImageColorMatrixFilter alloc] init];
    [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(identityMatrix4.entries)];
    NSLog(@"GPUImage colour matrix filter setup complete");
    
    [gpuCamera addTarget:gpuFilter];
    [gpuFilter addTarget:gpuView];
    
    gpuCamera.delegate = self;
    NSLog(@"GPUImage setup complete");
}
-(void)viewDidAppear:(BOOL)animated{
     NSLog(@"real time view did appear");
    [super viewDidAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    colorMatrix = identityMatrix4;
    
    [self initSound];
    
    NSLog(@"starting GPUImage camera capture");
    [gpuCamera startCameraCapture];
    NSLog(@"GPUImage camera capture started");
    
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"REAL TIME MODE DOES NOT WORK ON IPHONE SIMULATOR, BECAUSE CAMERA DOES NOT WORK ON IPHONE SIMULATOR.");
#endif
}
-(void)viewDidDisappear:(BOOL)animated{
    [gpuCamera stopCameraCapture];
    NSLog(@"stopped GPUImage camera capture");
    
    [self cleanSound];
    [super viewDidDisappear:animated];
    NSLog(@"real time view did disappear");
}
- (void)viewDidUnload {
    gpuCamera = nil;
    gpuView = nil;
    gpuFilter = nil;
    [self setFilterButton:nil];
    [self setBackButton:nil];
    [self setFilterListView:nil];
    [self setReticuleImage:nil];
    [self setRgdFilterButton:nil];
    [self setMarkGreenFilterButton:nil];
    [self setMarkRedFilterButton:nil];
    [self setClearFilterButton:nil];
    [self setBrightenGreenButton:nil];
    [self setBrightenRedButton:nil];
    [self setButtonGroup:nil];
    [super viewDidUnload];
    NSLog(@"real time view did unload");
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - ui control
-(IBAction)touchedBackButton:(id)sender{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - filter button actions
-(IBAction)touchedFilterButton:(id)sender{
    BOOL hiding = _filterListView.isHidden;
    if(hiding)
        NSLog(@"show filter list");
    else
        NSLog(@"hide filter list");
    [_filterListView setHidden:!hiding];

}

-(IBAction)pushFilter:(id)sender{
    struct mat4x4 const * filterMat;
    if(sender == _rgdFilterButton)
        filterMat = &redGreenDefficiencyMatrix;
    else if(sender == _markGreenFilterButton)
        filterMat = &markGreenMatrix;
    else if(sender == _markRedFilterButton)
        filterMat = &markRedMartix;
    else if(sender == _brightenGreenButton)
        filterMat = &brightenGreenMatrix;
    else if(sender == _brightenRedButton)
        filterMat = &brightenRedMatrix;
    else
        return;
    [gpuCamera stopCameraCapture];
    {
        struct mat4x4 dst;
        mat_mul(dst.entries, filterMat->entries, colorMatrix.entries, 4);
        colorMatrix = dst;
        [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(dst.entries)];
    }
    [gpuCamera startCameraCapture];
}
-(IBAction)clearFilters:(id)sender{
    [gpuCamera stopCameraCapture];
    {
        colorMatrix = identityMatrix4;
        [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(colorMatrix.entries)];
    }
    [gpuCamera startCameraCapture];
}

#pragma mark - sound
-(IBAction)sayColourName:(id)sender{
    
    NSString * name = [NSString stringWithFormat:@"%s %s",
                       brightness_string(brightness_id(rAvg, gAvg, bAvg)),
                       colour_string(colour_id(rAvg, gAvg, bAvg))];
    NSLog(@"say %@", name);
    dispatch_async(soundQueue, ^{
        [SpeechSynthesis say:name];
    });
}

- (void)initSound {
    [SpeechSynthesis initSingleton];
    soundQueue = dispatch_queue_create("sound_queue", NULL);
}
-(void)cleanSound{
    dispatch_release(soundQueue);
}

#pragma mark - capture functions
/* samples rgb value of center pixel*/
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
        if (counter)
        {
            counter--;
        }
        else
        {
            counter = 10;
            NSString * name = [NSString stringWithFormat:@"%03d %03d %03d %s %s",
                               rAvg, gAvg, bAvg,
                               brightness_string(brightness_id(rAvg, gAvg, bAvg)),
                               colour_string(colour_id(rAvg, gAvg, bAvg))];
            dispatch_sync(dispatch_get_main_queue(), ^{
                _bgrLabel.text = name;
            });
        }
    }
        
    CVPixelBufferUnlockBaseAddress(pixelBuf,kCVPixelBufferLock_ReadOnly);
}


@end
