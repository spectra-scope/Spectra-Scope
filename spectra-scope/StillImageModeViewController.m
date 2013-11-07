//
//  stillImageDisplay.m
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
 
bugs:
*/
#import "StillImageModeViewController.h"
#import "GPUImage.h"
#import "colour_name.h"
#import "ArcBuffer.h"
@interface StillImageModeViewController (){
    UIImagePickerController *picker;
    UIImage * image;
    ArcBuffer * pixelBuf;
}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *uiGroup;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
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
#pragma mark - viewdid
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
- (void)viewDidUnload {
    [self setUiGroup:nil];
    [self setImageView:nil];
    [self setInfoLabel:nil];
    [self setReticule:nil];
    [super viewDidUnload];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
    _imageView.frame = CGRectOffset(mainScreenFrame, 0, -20);
    [_imageView addSubview:_infoLabel];
    //_imageView.layer.affineTransform = CGAffineTransformMakeRotation(M_PI_2);
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - picker functions
- (IBAction)ChooseExisting{
    
    picker= [[UIImagePickerController alloc]init];
    picker.delegate= self;
    [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:picker animated:YES completion:NULL];
    
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    // get the image from picker, discard its orientation
    UIImage * pickerImageResult = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage * fixedImage = [UIImage imageWithCGImage:[pickerImageResult CGImage]
                                               scale:1.0
                                         orientation:UIImageOrientationRight];
    [self setupImageForProcessing:fixedImage];
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
    uint8_t * data = (uint8_t*)[bufObj head];
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
}
#pragma mark - ui control
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    CGFloat newx = _reticule.center.x + translation.x;
    if(newx < 0)
        newx = 0;
    else if(newx > self.view.bounds.size.width)
        newx = self.view.bounds.size.width;
    CGFloat newy = _reticule.center.y + translation.y;
    if(newy < 0)
        newy = 0;
    else if(newy > self.view.bounds.size.height)
        newy = self.view.bounds.size.height;
    _reticule.center = CGPointMake(newx, newy);
    NSLog(@"translation: %f, %f", translation.x, translation.y);
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

#pragma mark - processing
-(IBAction)queryColour:(id)sender{
    // use previously saved pixel array to get colour, instead of making a new pixel array every time
    // based on http://stackoverflow.com/a/1262893
    
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;

    uint8_t * pixels = (uint8_t*) [pixelBuf head];
    
    /*  all pictures are viewed in landscape, so the y is actually the inverted x position of the reticule
        , and x is actually the y position of the reticule
     */
    unsigned yy = ((self.view.bounds.size.width - _reticule.center.x) * height) / self.view.bounds.size.width;
    unsigned xx = (_reticule.center.y * width) / self.view.bounds.size.height;
    
    NSLog(@"image size: %d %d\n"
          @"query point: %d %d", width, height, xx, yy);
    
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    uint8_t r = pixels[byteIndex];
    uint8_t g = pixels[byteIndex + 1];
    uint8_t b = pixels[byteIndex + 2];
    
    char const * name = colour_string(colour_name(r, g, b));
    _infoLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d name:%s", r, g, b, name];
}
@end
