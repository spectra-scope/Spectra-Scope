//
//  OptionsViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-20.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - created
 1.1 by Tian Lin Tan
 - added option for upload data
 1.2 by Tian Lin Tan
 - added option for show rgb
 1.3 by Tian Lin Tan
 - added option for scope
 1.4 by Tian Lin Tan
 - hidden option for upload data
 - added background
 */
#import "OptionsViewController.h"
#import "AppDelegate.h"

@interface OptionsViewController ()
@property (nonatomic, getter = getProfile) UserProfile * profile;
@property (weak, nonatomic) IBOutlet UIButton *uploadButton;
@property (weak, nonatomic) IBOutlet UIButton *rgbButton;
@property (weak, nonatomic) IBOutlet UIButton *scopeButton;
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
    [self setScopeButton:nil];
    [super viewDidUnload];
}
#pragma mark - control flow
-(IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - option control
-(IBAction)toggleUploadData:(id)sender
{
    assert(sender == _uploadButton);
    self.profile.allowUploadUsageData = !self.profile.allowUploadUsageData;
    [self updateView];
}
-(IBAction)toggleShowRGB:(id)sender
{
    assert(sender == _rgbButton);
    self.profile.showRGB = !self.profile.showRGB;
    [self updateView];
}
-(IBAction)toggleScopeStyle:(id)sender
{
    assert(sender == _scopeButton);
    self.profile.scopeStyle = (self.profile.scopeStyle + 1) % SCOPE_LAST;
    [self updateView];
}

-(void) updateView
{
    NSString * uploadText = (self.profile.allowUploadUsageData ? @"YES" : @"NO");
    [_uploadButton setTitle:uploadText forState:UIControlStateNormal];
    
    NSString * rgbText = self.profile.showRGB ? @"YES" : @"NO";
    [_rgbButton setTitle:rgbText forState: UIControlStateNormal];
    
    NSString * scopeText = [scopeNames[self.profile.scopeStyle] copy];
    [_scopeButton setTitle:scopeText forState:UIControlStateNormal];
}
#pragma mark - lazy getter
-(UserProfile *)getProfile
{
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.currentProfile;
}
@end
