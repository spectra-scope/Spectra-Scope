//
//  stillImageDisplay.h
//  spectra-scope
//
//  Created by Archit Sood on 11/1/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RealTimeModeViewController.h"
@interface StillImageModeViewController : UIViewController<UIImagePickerControllerDelegate ,UINavigationControllerDelegate>
{
    FliteController *fliteController;
    Slt *slt;
    unsigned rAvg, gAvg, bAvg;
}

@property (strong, nonatomic) FliteController *fliteController;
@property (strong, nonatomic) Slt *slt;
@end



