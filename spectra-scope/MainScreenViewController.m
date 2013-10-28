//
//  MainScreenViewController.m
//  spectra-scope
//
//  Created by Archit Sood on 10/24/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Archit Sood
 - added image picker
 1.1: by Archit Sood
 - added camera code for real time mode
 1.2 by Tian Lin Tan
 - migrated camera function for real time mode to storyboard
 */
#import "MainScreenViewController.h"
@interface MainScreenViewController ()

@end

@implementation MainScreenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)ChooseExisting{
    
    picker2= [[UIImagePickerController alloc]init];
    picker2.delegate= self;
    [picker2 setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:picker2 animated:YES completion:NULL];
    
}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [imageView setImage: image];
    [self dismissViewControllerAnimated:YES completion:NULL];
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissViewControllerAnimated:YES completion:NULL];
}
@end
