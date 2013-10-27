//
//  MainScreenViewController.h
//  spectra-scope
//
//  Created by Archit Sood on 10/24/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainScreenViewController :UIViewController<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
{
    UIImagePickerController *picker;
    UIImagePickerController *picker2;
    UIImage *image;
    IBOutlet UIImageView *imageView;
    
}


-(IBAction)ChooseExisting;
@end
