//
//  ViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "ViewController.h"
#import "MainScreenViewController.h"
#import "UserProfile.h"
@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)logInPress:(id)sender {
    puts("loginpress");
    UserProfile * profile = [[UserProfile alloc] init];
    profile.username = _usernameInput.text;
    profile.password = _passwordInput.text;
    [profile login];

    if([profile loginWasSuccessful])
    {
        
        MainScreenViewController * next = [self.storyboard instantiateViewControllerWithIdentifier:@"mainScreen"];
        [self.navigationController pushViewController:next animated:YES];
    }
    else
    {
        _messageLabel.text = [profile loginStatusString];
        _messageLabel.textColor = [[UIColor alloc] initWithRed:255 green:0 blue:0 alpha:255];
    }
}

-(IBAction)backgroundTouched:(id)sender{
    [_usernameInput resignFirstResponder];
    [_passwordInput resignFirstResponder];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == _usernameInput || textField == _passwordInput)
        [textField resignFirstResponder];
    return YES;
}



- (void)viewDidUnload {
    [self setMessageLabel:nil];
    [super viewDidUnload];
}
@end
