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
/*
@interface Point2D : NSObject
@property (nonatomic, readwrite) unsigned x, y;
+(id) pointWith:(unsigned)x and:(unsigned)y;
@end

@implementation Point2D
+(id) pointWith:(unsigned)x and:(unsigned)y{
    Point2D * point = [[Point2D alloc] init];
    point.x = x;
    point.y = y;
    return point;
}
-(BOOL)isEqual:(id)object{
    Point2D * other = object;
    return _x == other.x && _y == other.y;
}
@end
*/

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
@property (weak, nonatomic) IBOutlet UIImageView *reticule;
@property (weak, nonatomic) IBOutlet UIImageView *playButton2;
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
    [_imageView addSubview:_infoLabel];
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
}
#pragma mark - ui control
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    CGPoint translation = [recognizer translationInView:self.view];
    
    CGFloat newx = _reticule.center.x + translation.x;
    newx = clip(newx, 0, self.view.bounds.size.width);
    
    CGFloat newy = _reticule.center.y + translation.y;
    newy = clip(newy, 0, self.view.bounds.size.height);
    
    _reticule.center = CGPointMake(newx, newy);
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
    
    /*  all pictures are viewed in landscape, so the y is actually the inverted x position of the reticule
        , and x is actually the y position of the reticule
     */
    NSUInteger yy = ((self.view.bounds.size.width - _reticule.center.x) * height) / self.view.bounds.size.width;
    yy = clip(yy, 0, height - 1);
    NSUInteger xx = (_reticule.center.y * width) / self.view.bounds.size.height;
    xx = clip(xx, 0, width - 1);
    
    pixel_t startPixel = pixels[width * yy + xx];
    rAvg = startPixel.r;
    gAvg = startPixel.g;
    bAvg = startPixel.b;
   
    struct point{unsigned x, y;} startPoint = {xx, yy};
    struct ringbuffer queue = ringbuffer_create(1000, sizeof(struct point));
    char * visited = calloc(width * height, 1);
    ringbuffer_enq(&queue, &startPoint);
    while(queue.len > 0)
    {
        struct point p;
        ringbuffer_top(&queue, &p);
        ringbuffer_deq(&queue);
        struct point neighbors[4] = {
            {p.x - 1, p.y}, {p.x, p.y + 1}, {p.x + 1, p.y}, {p.x, p.y - 1}
        };
        for(int i = 0; i < 4; i++)
        {
            if(!((neighbors[i].x >= width || neighbors[i].y >= height) ||
                (visited[neighbors[i].y * width + neighbors[i].x])))
            {
                visited[neighbors[i].y * width + neighbors[i].x] = 1;
                pixel_t a = pixels[p.y * width + p.x];
                pixel_t b = pixels[neighbors[i].y * width + neighbors[i].x];
                unsigned dif = pixel_dif(a, b);
                if(dif < 10 && queue.len < queue.size)
                    ringbuffer_enq(&queue, neighbors + i);
            }
        }
        pixel_t current = pixels[p.y * width + p.x];
        rAvg = (rAvg * 7 + current.r) / 8;
        gAvg = (gAvg * 7 + current.g) / 8;
        bAvg = (bAvg * 7 + current.b) / 8;
    }
    
   


    char const * colour_str = colour_string(colour_id(rAvg, gAvg, bAvg));
    char const * brightness_str = brightness_string(brightness_id(rAvg, gAvg, bAvg));
    _infoLabel.text = [NSString stringWithFormat:@"rgb:%03d %03d %03d %s %s", rAvg, gAvg, bAvg, brightness_str, colour_str];

}
@end
