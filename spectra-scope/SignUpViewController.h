//
//  SignUpViewController.h
//  spectra-scope
//
//  Created by tt on 13-10-23.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignUpViewController : UIViewController <UITextFieldDelegate>
-(IBAction)backgroundTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInputAgain;
@property (weak, nonatomic) IBOutlet UITextField *ageInput;

@end