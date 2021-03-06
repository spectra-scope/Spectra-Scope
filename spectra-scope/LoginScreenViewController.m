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
 2.0: by Tian Lin Tan
    - new buttons: contact and help
    - different layout
    - background image
 
 bugs:
 - view is not reset every time the screen this screen switches to other screens
 */
#import "LoginScreenViewController.h"
#import "MainScreenViewController.h"
#import "HelpViewController.h"
#import "UserProfile.h"
#import "AppDelegate.h"
@interface LoginScreenViewController ()
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic, getter = getMainScreenVC) UIViewController * mainScreenVC;
@property (strong, nonatomic, getter = getWebScreenVC) HelpViewController * webScreenVC;
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
    [self hideKeyboards:nil];
    [super viewDidDisappear:animated];
    NSLog(@"login view did disappear");
}
- (void)viewDidUnload {
    [self setMessageLabel:nil];
    [super viewDidUnload];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - button presses
- (IBAction)logInPress:(id)sender {
    NSLog(@"login pressed");
    UserProfile * profile = [[UserProfile alloc] init];
    profile.username = _usernameInput.text;
    profile.password = _passwordInput.text;
    
    AppDelegate * appDelegate = [[UIApplication sharedApplication] delegate];
    struct ini * profiles = appDelegate.profiles;
    [profile login:profiles];

    if([profile loginWasSuccessful])
    {
        appDelegate.currentProfile = profile;
        [self.navigationController pushViewController:self.mainScreenVC animated:YES];
    }
    else
    {
        _messageLabel.text = [profile loginStatusString];
        _messageLabel.textColor = [[UIColor alloc] initWithRed:255 green:0 blue:0 alpha:255];
        [self hideKeyboards:nil];
    }
}
-(IBAction)helpPage:(id)sender{
    [self.webScreenVC openPage:helpURL];
    [self.navigationController pushViewController:self.webScreenVC animated:YES];
}
-(IBAction)contactPage:(id)sender{
    [self.webScreenVC openPage:contactURL];
    [self.navigationController pushViewController:self.webScreenVC animated:YES];
}
#pragma mark - hiding keyboards
-(IBAction)hideKeyboards:(id)sender{
    NSLog(@"background touched, dismissing keyboard");
    [_usernameInput resignFirstResponder];
    [_passwordInput resignFirstResponder];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    NSLog(@"return touched, dismissing keyboard");
    if(textField == _usernameInput || textField == _passwordInput)
    {
        [textField resignFirstResponder];
        
    }
    return YES;
}
#pragma mark - keyboard animations
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    self.view.frame = CGRectOffset(self.view.frame, 0, -textField.frame.origin.y);
    [UIView commitAnimations];
    
}
-(void) textFieldDidEndEditing:(UITextField *)textField
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.2];
    self.view.frame = CGRectOffset(self.view.frame, 0, textField.frame.origin.y);
    [UIView commitAnimations];
}
#pragma mark - lazy getter
-(UIStoryboard*)storyboard{
    return [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
}
-(UIViewController*) getMainScreenVC{
    if(_mainScreenVC == nil)
    {
        _mainScreenVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MainScreenViewController"];
    }
    return _mainScreenVC;
}
-(UIViewController*) getWebScreenVC{
    if(_webScreenVC == nil)
    {
        _webScreenVC = [self.storyboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
    }
    return _webScreenVC;
}@end
