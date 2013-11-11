//
//  LoginScreenViewController.m
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
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic, getter = mainScreenVC) UIViewController * mainScreenVC;
@end

@implementation LoginScreenViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"authentication screen view did load");
	// Do any additional setup after loading the view, typically from a nib.
}
-(void) viewDidAppear:(BOOL)animated{
    NSLog(@"login view did appear");
    [super viewDidAppear:animated];
    _messageLabel.text = @"spectra-scope";
    _messageLabel.textColor = [[UIColor alloc] initWithRed:0 green:0 blue:0 alpha:255];
}
-(void)viewDidDisappear:(BOOL)animated{
    _usernameInput.text = @"";
    _passwordInput.text = @"";
    [super viewDidDisappear:animated];
    NSLog(@"login view did disappear");
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
        [self.navigationController pushViewController:self.mainScreenVC animated:YES];
    }
    else
    {
        _messageLabel.text = [profile loginStatusString];
        _messageLabel.textColor = [[UIColor alloc] initWithRed:255 green:0 blue:0 alpha:255];
    }
}
-(UIViewController*) mainScreenVC{
    if(_mainScreenVC == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
        _mainScreenVC = [storyboard instantiateViewControllerWithIdentifier:@"MainScreenViewController"];
    }
    return _mainScreenVC;
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
