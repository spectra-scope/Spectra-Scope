//
//  SignUpViewController.m
//  spectra-scope
//
//  Created by tt on 13-10-23.
//  Copyright (c) 2013 spectra. All rights reserved.
//
#define YEAH YES
#define NOT !
#import "SignUpViewController.h"

#import <string.h>
BOOL isProperName(NSString * str)
{
    unichar c;
    for(int i = 0; i < [str length]; i++)
    {
        c = [str characterAtIndex:i];
        BOOL proper = (c >= '0' && c <= '9') ||
            (c >= 'a' && c <= 'z') ||
            (c >= 'A' && c <= 'Z') ||
            (c == '_') ||
            (c == '-');
        if(!proper)
            return NO;
    }
    return YES;
}
BOOL isContinent(NSString * str)
{
    NSString * lower = [str lowercaseString];
    NSString * continentList[] = {@"north america" ,@"south america",
        @"africa",@"europe",@"asia",@"austrailia",@"antarctica",
        @"eurasia", @"americas", @"america",
        @"na",@"sa",@"as",@"eu",@"af",@"au",@"an"};
    for(int i = 0; i < sizeof(continentList) / sizeof(void*); i++)
        if([lower isEqual: continentList[i]])
            return YEAH;
    return NO;
}
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
    [_ethnicityInput resignFirstResponder];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == _usernameInput ||
       textField == _passwordInput ||
       textField == _passwordInputAgain ||
       textField == _ageInput ||
       textField == _ethnicityInput)
        [textField resignFirstResponder];
    return YES;
}
-(IBAction)signupButtonPress:(id)sender{
    UIColor * red = [[UIColor alloc] initWithRed:255 green: 0 blue:0 alpha:255];
    if(!isProperName(_usernameInput.text))
    {
        _messageLabel.text = @"invalid username";
        _messageLabel.textColor = red;
    }
    else if(!isProperName(_passwordInput.text))
    {
        _messageLabel.text = @"invalid password";
        _messageLabel.textColor = red;
    }
    else if(![_passwordInput.text isEqual: _passwordInputAgain.text])
    {
        _messageLabel.text = @"password mismatch";
        _messageLabel.textColor = red;
    }
    else if(![_ageInput.text isEqual:@""] && 0 == [_ageInput.text intValue])
    {
        _messageLabel.text = @"age must be numbers 1 to 120";
        _messageLabel.textColor = red;
    }
    else if(NOT isContinent(_ethnicityInput.text))
    {
        _messageLabel.text = @"invalid continent of orign";
        _messageLabel.textColor = red;
    }
    else
        [self.navigationController popViewControllerAnimated: YES];
}
@end
