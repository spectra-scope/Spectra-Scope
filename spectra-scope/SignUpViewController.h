//
//  SignUpViewController.h
//  spectra-scope
//
//  Created by tt on 13-10-23.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added properties for username, password, confirm password, age, continent, sex, and message label
 */
#import <UIKit/UIKit.h>

@interface SignUpViewController : UIViewController <UITextFieldDelegate>
-(IBAction)backgroundTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputAgain;
@property (weak, nonatomic) IBOutlet UITextField *ageInput;
@property (weak, nonatomic) IBOutlet UITextField *ethnicityInput;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *sexButton;

@end
