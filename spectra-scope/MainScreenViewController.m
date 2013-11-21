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
 1.3 by Tian Lin Tan
 - transition to real time or still image mode is no longer done in story board
 - instead, instances of next view controllers are kept
 */
#import "MainScreenViewController.h"
#import "RealTimeModeViewController.h"
@interface MainScreenViewController ()
@property (weak, nonatomic) IBOutlet UIButton *realTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *stillImageButton;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (strong, nonatomic, getter = realTimeModeVC) UIViewController * realTimeModeVC;
@property (strong, nonatomic, getter = stillImageModeVC) UIViewController * stillImageModeVC;
@property (strong, nonatomic, getter = optionsVC) UIViewController * optionsVC;
@end

@implementation MainScreenViewController

#pragma mark - init and tear down
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
    NSLog(@"main screen view did load");
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
- (void)viewDidUnload {
    [self setRealTimeButton:nil];
    [self setStillImageButton:nil];
    [self setOptionsButton:nil];
    [super viewDidUnload];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - flow control
-(IBAction)gotoNextScreen:(id)sender{
    UIViewController * next = nil;
    if(sender == _realTimeButton)
        next = self.realTimeModeVC;
    else if(sender == _stillImageButton)
        next = self.stillImageModeVC;
    else if(sender == _optionsButton)
        next = self.optionsVC;
    else
        return;
    
    [self.navigationController setNavigationBarHidden:(sender != _optionsButton) animated:YES];
    
    [self.navigationController pushViewController:next animated:YES];
}

#pragma mark - view controller lazy getters
-(UIViewController*) realTimeModeVC{
    if(_realTimeModeVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        _realTimeModeVC = [storyboard instantiateViewControllerWithIdentifier:@"RealTimeModeViewController"];
    }
    return _realTimeModeVC;
}
-(UIViewController*) stillImageModeVC{
    if(_stillImageModeVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        _stillImageModeVC = [storyboard instantiateViewControllerWithIdentifier:@"StillImageModeViewController"];
    }
    return _stillImageModeVC;
}
-(UIViewController*) optionsVC{
    if(_optionsVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        _optionsVC = [storyboard instantiateViewControllerWithIdentifier:@"OptionsViewController"];
    }
    return _optionsVC;
}

@end
