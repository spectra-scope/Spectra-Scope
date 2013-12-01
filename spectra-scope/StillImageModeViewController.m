//
//  StillImageModeViewController.m
//  spectra-scope
//
//  Created by Archit Sood on 11/1/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

/*
revisions:
 1.0: by Tian Lin Tan
 - changed layout of ui
 - navigation controller is not always hidden
 1.1: by Tian Lin Tan
 - added reticule for aiming colour query
 - added gesture recognizer to aim reticule
 - added function to query colour info at reticule
 1.2: by Tian Lin Tan
 - changed to use flood fill algorithm with tolerance and moving average to find colour
 1.3: by Tian Lin Tan
 - changed terminlogy:
    tolerance -> local tolerance
    deviation -> global tolerance
 1.4: by Tian Lin Tan
 - changed operation:
    instead of draggin reticule, reticule is now fixed. the image is dragged around instead.
 - changed orientation:
    images are now displayed in the same orientation as its pixels are stored
 
bugs:
 - index out of bounds when querying the corner pixels (fixed with cliping of index first)
*/


#import "StillImageModeViewController.h"
#import "colour_name.h"
#import "ArcBuffer.h"
#import "ringbuffer.h"

#import "GPUImage.h"

#import "SpeechSynthesis.h"

#define clip(n, lo, hi)((n) < (lo) ? (lo) : (n) > (hi) ? (hi) : (n))

// size of the queue for the algorithm
#define QUEUE_SIZE 1024

// allowable difference between neighbor pixels
#define LOCAL_TOLERANCE 20

//allowable difference between pixel and starting pixel
#define GLOBAL_TOLERANCE 100

@interface StillImageModeViewController (){
    UIImagePickerController *picker;
    UIImage * image;
    ArcBuffer * pixelBuf;
    unsigned rAvg, gAvg, bAvg;
    dispatch_queue_t soundQueue;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *uiGroup;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIImageView *reticule;
@end

@implementation StillImageModeViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
#pragma mark - viewdidsomething
- (void)viewDidLoad{
    NSLog(@"still image view did load");
    [super viewDidLoad];
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    _imageView.frame = CGRectOffset(mainScreenFrame, 0, -20);
}
-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"still image view did appear");
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self initSound];
}
-(void) viewDidDisappear:(BOOL)animated{
    [self cleanSound];
    
   
    [super viewDidDisappear:animated];
    NSLog(@"still image view did disappear");
}
- (void)viewDidUnload {
    image = nil;
    pixelBuf = nil;
    [self setUiGroup:nil];
    [self setImageView:nil];
    [self setInfoLabel:nil];
    [self setPlayButton:nil];
    [self setReticule:nil];
    [super viewDidUnload];
    NSLog(@"still image view did unload");
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - picker functions
- (IBAction)choosePicture{
    picker= [[UIImagePickerController alloc] init];
    picker.delegate= self;
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:picker animated:YES completion:NULL];
    
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    // get the image from picker, discard its orientation
    UIImage * pickerImageResult = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage * fixedImage = [UIImage imageWithCGImage:[pickerImageResult CGImage]
                                               scale:1.0
                                         orientation:UIImageOrientationUp];
    [self setupImageForProcessing:fixedImage];
    _imageView.bounds = CGRectMake(0, 0, fixedImage.size.width, fixedImage.size.height);
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(void) setupImageForProcessing:(UIImage*) img{
    // first save a copy of the unmodified image
    image = img;
    [_imageView setImage:img];
    
    // then save pixel array in memory
    // based on http://stackoverflow.com/a/1262893
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    ArcBuffer * bufObj = [[ArcBuffer alloc ] initWithSize:height * width * 4 * sizeof(uint8_t)];
    char * data = [bufObj head];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    pixelBuf = bufObj;
    NSLog(@"%d, %d", width, height);
}
#pragma mark - ui control
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    
    CGFloat newx = _imageView.frame.origin.x + translation.x;
    CGFloat newy = _imageView.frame.origin.y + translation.y;
    if(newx > _reticule.center.x)
        newx = _reticule.center.x;
    if(newy > _reticule.center.y)
        newy = _reticule.center.y;
    if(newx + _imageView.frame.size.width < _reticule.center.x)
        newx = _reticule.center.x - _imageView.frame.size.width;
    if(newy + _imageView.frame.size.height < _reticule.center.y)
        newy = _reticule.center.y - _imageView.frame.size.height;
    _imageView.frame = CGRectMake(newx, newy, _imageView.frame.size.width, _imageView.frame.size.height);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
}
- (IBAction)showHideUIGroup:(id)sender {
    BOOL hidden = [_uiGroup isHidden];
    if(hidden)
        NSLog(@"showing ui");
    else
        NSLog(@"hiding ui");
    [_uiGroup setHidden:!hidden];
    
}
-(IBAction)touchedBackButton:(id)sender{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - sound
-(IBAction)sayColourName:(id)sender{
    NSString *name = [NSString stringWithFormat:@"%s %s",
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
#pragma mark - processing
-(IBAction)queryColour:(id)sender{
    if(pixelBuf == nil)
        return;
    // use previously saved pixel array to get colour, instead of making a new pixel array every time
    // based on http://stackoverflow.com/a/1262893
    
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);

    
    assert(sizeof(pixel_t) == 4);
    pixel_t * pixels = pixelBuf.head;
    

    NSInteger x = _reticule.center.x - _imageView.frame.origin.x;
    x = clip(x, 0, width - 1);
    NSInteger y = _reticule.center.y - _imageView.frame.origin.y;
    y = clip(y, 0, height - 1);

    pixel_t result = colour_average(pixels, width, height, x, y, LOCAL_TOLERANCE, GLOBAL_TOLERANCE, QUEUE_SIZE);
    rAvg = result.r;
    gAvg = result.g;
    bAvg = result.b;


    char const * colour_str = colour_string(colour_id(rAvg, gAvg, bAvg));
    char const * brightness_str = brightness_string(brightness_id(rAvg, gAvg, bAvg));
    _infoLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d %s %s", rAvg, gAvg, bAvg, brightness_str, colour_str];

}
@end
