//
//  CreditsViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-21.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - created
 2.0 by Tian Lin Tan
 - added background
 */
#import "CreditsViewController.h"

@interface CreditsViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CreditsViewController

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
	_textView.text =
    @"Project management\n"
    "Archit Sood\n"
    "\n"
    
    "Website\n"
    "Archit Sood\n"
    "\n"
    
    "Icons\n"
    "Daniel Soheili\n"
    "Nikita Chichikov\n"
    "\n"
    
    "Logo design\n"
    "Daniel Soheili\n"
    "\n"
    
    "Documentation\n"
    "Archit Sood\n"
    "Daniel Soheili\n"
    "Nikita Chizhikov\n"
    "Ying Chen\n"
    "\n"
    
    "Diagramming\n"
    "Archit Sood\n"
    "Ying Chen\n"
    "Tian Lin Tan\n"
    "\n"
    
    "Programming\n"
    "Archit Sood\n"
    "Tian Lin Tan\n"
    "\n"
    
    "Quality assurance\n"
    "Nikita Chizhikov\n"
    "\n"
    
    "Team agent\n"
    "Herbert Tsang\n"
    "\n"
    
    "Team admin\n"
    "Yong Liao\n"
    "\n"
    
    "Third party software\n"
    "GPUImage\n"
    "Openears\n"
    "\n"
    ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTextView:nil];
    [super viewDidUnload];
}
#pragma mark - flow control
-(IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
