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
 2.0 by Tian Lin Tan
 - added background
 - added logout button
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
    // decide which screen to go to next, based on the sender button
    UIViewController * next = nil;
    if(sender == _realTimeButton)
        next = self.realTimeModeVC;
    else if(sender == _stillImageButton)
        next = self.stillImageModeVC;
    else if(sender == _optionsButton)
        next = self.optionsVC;
    else
        return;
    
    // hide the navigation controller bar if not going to options screen
    //[self.navigationController setNavigationBarHidden:(sender != _optionsButton) animated:YES];
    
    // pushit
    [self.navigationController pushViewController:next animated:YES];
}
-(IBAction)logout:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - lazy getters
-(UIViewController*) realTimeModeVC{
    if(_realTimeModeVC == nil)
    {
        _realTimeModeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"RealTimeModeViewController"];
    }
    return _realTimeModeVC;
}
-(UIViewController*) stillImageModeVC{
    if(_stillImageModeVC == nil)
    {
        _stillImageModeVC = [self.storyboard instantiateViewControllerWithIdentifier:@"StillImageModeViewController"];
    }
    return _stillImageModeVC;
}
-(UIViewController*) optionsVC{
    if(_optionsVC == nil)
    {
        _optionsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OptionsViewController"];
    }
    return _optionsVC;
}
-(UIStoryboard*)getStoryboard{
    return [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
}

@end
