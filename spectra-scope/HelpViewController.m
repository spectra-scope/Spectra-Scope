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
	NSURL *URL = [NSURL URLWithString:@"http://cmpt275-group3.businesscatalyst.com/help.html"];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:URL];
    _webView.delegate = self ;
    [_webView loadRequest:requestObj];
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
#pragma mark - flow control
-(IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
