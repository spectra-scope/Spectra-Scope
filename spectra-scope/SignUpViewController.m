//
//  SignUpViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-10-23.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added backgroundTouched for dismissing keyboards
 - added testFieldShouldReturn for dismissing keyboards
 1.1: by Tian Lin Tan
 - added sign up input sanitation
 1.2: by Tian Lin Tan
 - added isContinent for checking if string is a valid continent
 1.3: by Archit Sood
 - added isInt for checking if string is an integer
 1.4: by Tian Lin Tan
 - added isProperName for checking if input string contains only valid characters for username or password
 1.5: by Tian Lin Tan
 - added sex button toggle function for toggling sex every time the sex button is pressed
 1.6: by Tian Lin Tan
 - added code for sign up
 */
#import "SignUpViewController.h"
#import "UserProfile.h"
#import "AppDelegate.h"
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
        
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    sex = SEX_NONE;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - text field and keyboard
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
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectOffset(self.view.frame, 0, -textField.frame.origin.y);
    [UIView commitAnimations];
    
}
-(void) textFieldDidEndEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.25];
    self.view.frame = CGRectOffset(self.view.frame, 0, textField.frame.origin.y);
    [UIView commitAnimations];
}
#pragma mark - buttons
-(IBAction)sexButtonPress:(id)sender{
    
    sex = (sex + 1) % SEX_LAST;
    [_sexButton setTitle:[sexNames[sex] copy] forState:UIControlStateNormal];
}

/* the sign up process in action.
 a sequence of error checking will be done to make sure
 input is valid.
 */

-(IBAction)signupButtonPress:(id)sender{
    UIColor * red = [[UIColor alloc] initWithRed:255 green: 0 blue:0 alpha:255];
    
    // first to input sanitization
    unsigned age = [_ageInput.text intValue];
    if([_usernameInput.text length] == 0 ||
       [_passwordInput.text length] == 0 ||
       [_passwordInputAgain.text length] == 0)
    {
        _messageLabel.text = @"required fields must not be empty";
        _messageLabel.textColor = red;
    }
    else if([_usernameInput.text length] > 40)
    {
        _messageLabel.text = @"username must be under 40 symbols";
        _messageLabel.textColor = red;
    }
    else if([_passwordInput.text length] > 40)
    {
        _messageLabel.text = @"password must be under 40 symbols";
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
    
    // finally try signing up
    else
    {
        UserProfile * newProfile = [[UserProfile alloc] init];
        newProfile.username = _usernameInput.text;
        newProfile.password = _passwordInput.text;
        newProfile.continent = _ethnicityInput.text;
        newProfile.age = age;
        newProfile.sex = sex;
        
        AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
        struct ini * profiles = appDelegate.profiles;
        [newProfile signup:profiles];
        
        if([newProfile signupWasSuccessful])
            [self.navigationController popViewControllerAnimated: YES];
        else
        {
            _messageLabel.text = [newProfile signupStatusString];
            _messageLabel.textColor = red;
        }
    }
}
@end
