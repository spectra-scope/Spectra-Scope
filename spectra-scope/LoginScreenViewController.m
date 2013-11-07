//
//  ViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

/*
revisions:
 1.0: by Tian Lin Tan
    - added backgroundTouched for dismissing keyboards
    - added testFieldShouldReturn for dismissing keyboards
 1.1: by Tian Lin Tan
    - added logInPress for checking login input
 
 bugs:
 - view is not reset every time the screen this screen switches to other screens
 */
#import "LoginScreenViewController.h"
#import "MainScreenViewController.h"
#import "UserProfile.h"
@interface LoginScreenViewController ()

@end

@implementation LoginScreenViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"enter authentication screen");
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)logInPress:(id)sender {
    NSLog(@"login pressed");
    UserProfile * profile = [[UserProfile alloc] init];
    profile.username = _usernameInput.text;
    profile.password = _passwordInput.text;
    [profile login];

    if([profile loginWasSuccessful])
    {
        _messageLabel.text = @"spectra-scope";
        _messageLabel.textColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:255];
        [self performSegueWithIdentifier: @"loginSegue" sender: self];
    }
    else
    {
        _messageLabel.text = [profile loginStatusString];
        _messageLabel.textColor = [[UIColor alloc] initWithRed:255 green:0 blue:0 alpha:255];
    }
}

-(IBAction)backgroundTouched:(id)sender{
    NSLog(@"background touched, dismissing keyboard");
    [_usernameInput resignFirstResponder];
    [_passwordInput resignFirstResponder];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"return touched, dismissing keyboard");
    if(textField == _usernameInput || textField == _passwordInput)
        [textField resignFirstResponder];
    return YES;
}



- (void)viewDidUnload {
    [self setMessageLabel:nil];
    [super viewDidUnload];
}
@end
