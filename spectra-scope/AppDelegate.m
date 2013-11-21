//
//  AppDelegate.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-10-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "AppDelegate.h"
#import "UserProfile.h"
#import "iniparser.h"


@implementation AppDelegate
@synthesize profiles;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    profiles = ini_new();
    [self readProfile];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"app will resign active");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self writeProfile];
    NSLog(@"app did enter background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground.
    
    ini_del(profiles);
    profiles = NULL;
    NSLog(@"app will terminate");
}

-(NSString*) getProfilePath
{
    //get the documents directory:
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * dir = [paths objectAtIndex:0];
    NSLog(@"%@", dir);
    return [NSString stringWithFormat:@"%@/profiles.txt", dir];
    
}
-(BOOL) readProfile
{
    if(profiles != NULL)
    {
        NSString * profile_path = [self getProfilePath];
        FILE * fid;
        fid = fopen([profile_path UTF8String], "r");
        if(fid != NULL)
        {
            ini_read(profiles, fid);
            fclose(fid);
            return YES;
        }
        else
            return NO;
    }
    else
        return NO;
}
-(BOOL) writeProfile
{
    if(profiles != NULL)
    {
        NSString * profile_path = [self getProfilePath];
        FILE * fid;
        fid = fopen([profile_path UTF8String], "w");
        if(fid != NULL)
        {
            ini_write(profiles, fid);
            fclose(fid);
            return YES;
        }
        else
            return NO;
    }
    else
        return NO;
}

@end
