//
//  ViewController.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added properties for text fields and label
 */
#import <UIKit/UIKit.h>

@interface LoginScreenViewController : UIViewController<UITextFieldDelegate >


-(IBAction)backgroundTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@end 


