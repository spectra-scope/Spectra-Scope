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
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
