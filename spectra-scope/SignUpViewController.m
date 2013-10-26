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
    NSString * continentList[] = {
        @"north america" ,@"south america",
        @"africa",@"europe",@"asia",@"austrailia",@"antarctica",
        
        @"eurasia", @"americas", @"america",
        
        @"na",@"sa",@"as",@"eu",@"af",@"au",@"an", @""};
    for(int i = 0; i < sizeof(continentList) / sizeof(void*); i++)
        if([lower isEqual: continentList[i]])
            return YES;
    return NO;
}
BOOL isInt(NSString * str)
{
    for(int i = 0; i < [str length]; i++)
    {
        unichar c = [str characterAtIndex:i];
        if(c < '0' || c > '9')
            return NO;
    }
    return YES;
}

/* a list of all available sexes*/
enum sex{
    NONE,
    MALE,
    FEMALE,
    OTHER,
    SEX_LAST
};
static NSString * sexNames[] = {
    [NONE] = @"none",
    [MALE] = @"male",
    [FEMALE] = @"female",
    [OTHER] = @"other"
};
@interface SignUpViewController ()
{
    enum sex sex;
    
}
@end

@implementation SignUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        sex = NONE;
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

/* toggles sex using modulo*/
-(IBAction)sexButtonPress:(id)sender{
    
    sex = (sex + 1) % SEX_LAST;
    [_sexButton setTitle:sexNames[sex] forState:UIControlStateNormal];
}

/* the sign up process in action.
 a sequence of error checking will be done to make sure
 input is valid.
 */
-(IBAction)signupButtonPress:(id)sender{
    UIColor * red = [[UIColor alloc] initWithRed:255 green: 0 blue:0 alpha:255];
    unsigned age = [_ageInput.text intValue];
    if([_usernameInput.text length] == 0 ||
       [_passwordInput.text length] == 0 ||
       [_passwordInputAgain.text length] == 0)
    {
        _messageLabel.text = @"required fields must not be empty";
        _messageLabel.textColor = red;
    }
    else if(!isProperName(_usernameInput.text))
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
    else if(![_ageInput.text isEqual:@""] && (!isInt(_ageInput.text) || age > 120))
    {
        _messageLabel.text = @"age must be numbers 1 to 120";
        _messageLabel.textColor = red;
    }
    else if(!isContinent(_ethnicityInput.text))
    {
        _messageLabel.text = @"invalid continent of orign";
        _messageLabel.textColor = red;
    }
    else
        [self.navigationController popViewControllerAnimated: YES];
}
@end
