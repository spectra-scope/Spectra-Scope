//
//  stillImageDisplay.h
//  spectra-scope
//
//  Created by Archit Sood on 11/1/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface stillImageDisplay : UIViewController<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
{
    UIImagePickerController *picker;
    UIImagePickerController *picker2;
    UIImage *image;
    IBOutlet UIImageView *imageView;
    
}

// opens up an image chooser
-(IBAction)ChooseExisting;
@end



