//
//  HelpViewController.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 11/28/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController<UIWebViewDelegate>
-(void)openPage:(NSString*)urlString;
@end
