//
//  ViewController.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UITextFieldDelegate>
-(IBAction)backgroundTouched:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameInput;
@property (weak, nonatomic) IBOutlet UITextField *passwordInput;
@end
