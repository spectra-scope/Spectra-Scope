//
//  MainScreenViewController.m
//  spectra-scope
//
//  Created by Archit Sood on 10/24/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Archit Sood
 - added image picker
 1.1: by Archit Sood
 - added camera code for real time mode
 1.2 by Tian Lin Tan
 - migrated camera function for real time mode to storyboard
 */
#import "MainScreenViewController.h"
#import "RealTimeModeViewController.h"
@interface MainScreenViewController ()
{
    UIViewController * realTimeModeVC;
    UIViewController * stillImageModeVC;
}
@property (weak, nonatomic) IBOutlet UIButton *realTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *stillImageButton;
@end

@implementation MainScreenViewController

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
    NSLog(@"main screen did load: %p", self);
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)gotoNextScreen:(id)sender{
    UIViewController * next = nil;
    if(sender == _realTimeButton)
        next = [self realTimeModeVC];
    else if(sender == _stillImageButton)
        next = [self stillImageModeVC];
    else
        return;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController pushViewController:next animated:YES];
}
-(UIViewController*) realTimeModeVC{
    if(realTimeModeVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        realTimeModeVC = [storyboard instantiateViewControllerWithIdentifier:@"RealTimeModeViewController"];
    }
    return realTimeModeVC;
}
-(UIViewController*) stillImageModeVC{
    if(stillImageModeVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        stillImageModeVC = [storyboard instantiateViewControllerWithIdentifier:@"StillImageModeViewController"];
    }
    return stillImageModeVC;
}
- (void)viewDidUnload {
    [self setRealTimeButton:nil];
    [self setStillImageButton:nil];
    [super viewDidUnload];
}
@end
