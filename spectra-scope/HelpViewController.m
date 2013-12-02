//
//  HelpViewController.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 11/28/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSURLRequest * requestObj;
@end

@implementation HelpViewController

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
	
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _webView.delegate = self ;
    [_webView loadRequest:_requestObj];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [super viewDidUnload];
}
#pragma mark - 
-(void)openPage:(NSString*)urlString{
    NSURL *URL = [NSURL URLWithString:urlString];
    _requestObj = [NSURLRequest requestWithURL:URL];
    
}
#pragma mark - flow control
-(IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
