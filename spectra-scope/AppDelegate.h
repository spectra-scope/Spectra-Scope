//
//  AppDelegate.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iniparser.h"
#import "UserProfile.h"
extern NSString const * const scopeImgPath[];
extern NSString * helpURL;
extern NSString * contactURL;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly) struct ini * profiles;
@property (strong, nonatomic) UserProfile * currentProfile;
@end
