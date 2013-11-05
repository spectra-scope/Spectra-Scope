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
 1.7: by Tian Lin Tan
 - added library GPUImage, for real time filtering
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
#import "matrix.h"
struct mat4x4{
    float entries[16];
};
static struct mat4x4 const identityMatrix4 = {{
1.0, 0, 0, 0,
0, 1.0, 0, 0,
0, 0, 1.0, 0,
0, 0, 0, 1.0
}},
redGreenDefficiencyMatrix = {{
0.5, 0.5, 0, 0,
0.5, 0.5, 0, 0,
0, 0, 1, 0,
0, 0, 0, 1
}},
markGreenMatrix = {{
-0.5, 1.0, -0.5, 0,
-0.5, 1.0, -0.5, 0,
-0.5, 1.0, -0.5, 0,
0, 0, 0, 1
}},
markRedMartix = {{
1.0, -0.5, -0.5, 0,
1.0, -0.5, -0.5, 0,
1.0, -0.5, -0.5, 0,
0, 0, 0, 1
}},
brightenGreenMatrix = {{
    1, 0, 0, 0,
    -0.3, 1.3, -0.3, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
}},
brightenRedMatrix = {{
    1.3, -0.3, -0.3, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
}};
GPUMatrix4x4 GPUMatrix4x4FromArray(float const * a)
{
    return (GPUMatrix4x4){
        {a[0], a[1], a[2], a[3]},
        {a[4], a[5], a[6], a[7]},
        {a[8], a[9], a[10], a[11]},
        {a[12], a[13], a[14], a[15]}
    };
}
@interface RealTime ()
{
    BOOL hiddenFilterList;
    unsigned rAvg, gAvg, bAvg;
    unsigned counter;
    GPUImageVideoCamera * gpuCamera;
    GPUImageView * gpuView;
    GPUImageColorMatrixFilter * gpuFilter;
    struct mat4x4 colorMatrix;
}

@property (weak, nonatomic) IBOutlet UILabel *bgrLabel;
@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *filterListView;
@property (weak, nonatomic) IBOutlet UIImageView *reticuleImage;
@property (weak, nonatomic) IBOutlet UIButton *rgdFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *markGreenFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *markRedFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *clearFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *brightenGreenButton;
@property (weak, nonatomic) IBOutlet UIButton *brightenRedButton;
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
    }
    return self;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    hiddenFilterList = YES;
    [_filterListView setHidden:hiddenFilterList];
    colorMatrix = identityMatrix4;
    [self startCapture];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    gpuView = nil;
    gpuCamera = nil;
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
    [super viewDidUnload];
}
-(void)viewDidDisappear:(BOOL)animated{
    [gpuCamera stopCameraCapture];
    gpuCamera = nil;
    gpuView = nil;
    gpuFilter = nil;
    NSLog(@"stopped capturing");
    
    [super viewDidDisappear:animated];
}

// toggle the hiding of the navigation bar
-(IBAction)touchedView:(id)sender{
    NSLog(@"tickles");
}
-(IBAction)touchedBackButton:(id)sender{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark filter button actions
-(IBAction)touchedFilterButton:(id)sender{
    hiddenFilterList = !hiddenFilterList;
    if(hiddenFilterList)
    {
        [_filterListView setHidden:YES];
        NSLog(@"hide filter list");
        
    }
    else
    {
        [_filterListView setHidden:NO];
        NSLog(@"show filter list");
    }

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
    [gpuCamera pauseCameraCapture];
    {
        struct mat4x4 dst;
        mat_mul(dst.entries, filterMat->entries, colorMatrix.entries, 4);
        colorMatrix = dst;
        [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(dst.entries)];
    }
    [gpuCamera resumeCameraCapture];
}
-(IBAction)clearFilters:(id)sender{
    [gpuCamera pauseCameraCapture];
    {
        colorMatrix = identityMatrix4;
        [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(colorMatrix.entries)];
    }
    [gpuCamera resumeCameraCapture];
}
/* startCapture is the final setup step to perform before the screen can display what the camera captures.*/
-(void) startCapture{
    NSLog(@"GPUImage capture setup");
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    
    gpuCamera = [[GPUImageVideoCamera alloc]
                 initWithSessionPreset:AVCaptureSessionPreset640x480
                 cameraPosition:AVCaptureDevicePositionBack];
    gpuCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    gpuView = [[GPUImageView alloc] initWithFrame:CGRectOffset(mainScreenFrame, 0, -20)];
    [self.view addSubview:gpuView];
    
    gpuFilter = [[GPUImageColorMatrixFilter alloc] init];
    [gpuFilter setColorMatrix:GPUMatrix4x4FromArray(identityMatrix4.entries)];
    
    [gpuCamera addTarget:gpuFilter];
    [gpuFilter addTarget:gpuView];
    
    gpuCamera.delegate = self;
    
    [gpuView addSubview:_bgrLabel];
    [gpuView addSubview:_filterButton];
    [gpuView addSubview:_backButton];
    [gpuView addSubview:_filterListView];
    [gpuView addSubview:_reticuleImage];
    _reticuleImage.center = gpuView.center;
    
    [gpuCamera startCameraCapture];
    NSLog(@"GPUImage capture setup complete, capture started");
}

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
            char const * name = colour_string(colour_name(r, g, b));
            dispatch_sync(dispatch_get_main_queue(), ^{
                _bgrLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d name:%s", rAvg, gAvg, bAvg, name];
            });
        }
    }
        
    CVPixelBufferUnlockBaseAddress(pixelBuf,kCVPixelBufferLock_ReadOnly);
}


@end
