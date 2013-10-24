//
//  SignUpViewController.m
//  spectra-scope
//
//  Created by tt on 13-10-23.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "SignUpViewController.h"

@interface SignUpViewController ()

@end

@implementation SignUpViewController

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
-(IBAction)backgroundTouched:(id)sender{
    [_usernameInput resignFirstResponder];
    [_passwordInput resignFirstResponder];
    [_passwordInputAgain resignFirstResponder];
    [_ageInput resignFirstResponder];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == _usernameInput ||
       textField == _passwordInput ||
       textField == _passwordInputAgain ||
       textField == _ageInput)
        [textField resignFirstResponder];
    return YES;
}
-(IBAction)signupButtonPress:(id)sender{
    [self.navigationController popViewControllerAnimated: YES];
}

@end
