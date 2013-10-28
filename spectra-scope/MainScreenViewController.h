//
//  MainScreenViewController.h
//  spectra-scope
//
//  Created by Archit Sood on 10/24/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Archit Sood
 - added member fields
 1.1: by Archit Sood
 - conforms to UIImagePickerControllerDelegate and UINavigationControllerDelegate for the image picker
 */
#import <UIKit/UIKit.h>

@interface MainScreenViewController :UIViewController<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
{
    UIImagePickerController *picker;
    UIImagePickerController *picker2;
    UIImage *image;
    IBOutlet UIImageView *imageView;
    
}

// opens up an image chooser
-(IBAction)ChooseExisting;
@end
