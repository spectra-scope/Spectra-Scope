//
//  stillImageDisplay.m
//  spectra-scope
//
//  Created by Archit Sood on 11/1/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "stillImageDisplay.h"

@interface stillImageDisplay ()
@property (weak, nonatomic) IBOutlet UIView *uiGroup;

@end

@implementation stillImageDisplay

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
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
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
-(IBAction)hideUI:(id)sender{
    NSLog(@"hide ui");
    [_uiGroup setHidden:YES];
}
-(IBAction)showUI:(id)sender{
    NSLog(@"show ui");
    [_uiGroup setHidden:NO];
}
- (void)viewDidUnload {
    [self setUiGroup:nil];
    [super viewDidUnload];
}
@end
