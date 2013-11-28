//
//  OptionsViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-20.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "OptionsViewController.h"
#import "AppDelegate.h"

@interface OptionsViewController ()
@property (nonatomic, getter = getProfile) UserProfile * profile;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UIButton *rgbButton;
@end

@implementation OptionsViewController

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
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateView];
    
}
-(void)viewDidDisappear:(BOOL)animated
{
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.currentProfile update:appDelegate.profiles];
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
    [self setUploadButton:nil];
    [self setRgbButton:nil];
    [super viewDidUnload];
}

-(UserProfile *)getProfile
{
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.currentProfile;
}
-(IBAction)uploadButtonPress:(id)sender
{
    assert(sender == _uploadButton);
    self.profile.allowUploadUsageData = !self.profile.allowUploadUsageData;
    [self updateView];
}
-(void) updateView
{
    NSString * uploadText = (self.profile.allowUploadUsageData ? @"YES" : @"NO");
    [_uploadButton setTitle:uploadText forState:UIControlStateNormal];
    
    NSString * rgbText = self.profile.showRGB ? @"YES" : @"NO";
    [_rgbButton setTitle:rgbText forState: UIControlStateNormal];
}
@end
