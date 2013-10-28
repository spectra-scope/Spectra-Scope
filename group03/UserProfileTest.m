//
//  UserProfileTest.m
//  spectra-scope
//
//  Created by tt on 13-10-27.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "UserProfileTest.h"
#import "UserProfile.h"
@interface UserProfileTest ()
{
    NSDictionary * userList;
}
@end
@implementation UserProfileTest
- (void)setUp
{
    [super setUp];
    
    // register some users
    UserProfile * profile = [[UserProfile alloc] init];
    userList = @{@"a":@"a", @"b":@"b", @"c": @"c", @"d":@"d"};
    for (NSString * key in userList) {
        profile.username = key;
        profile.password = [userList objectForKey:key];
        [profile signUp];
    }

    
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}
-(void)testSignup{
    UserProfile * profile = [[UserProfile alloc] init];
    for (NSString * name in userList)
    {
        profile.username = @"a";
        [profile signUp];
        if([profile signUpWasSuccessful])
            STFail(@"sign up failed to reject existing username");
    }
}
- (void)testAuthentication
{
    UserProfile * profile = [[UserProfile alloc] init];
    for (NSString * name in userList)
    {
        profile.username = name;
        profile.password = [userList objectForKey: name];
        [profile login];
        if(![profile loginWasSuccessful])
            STFail(@"login %@ : %@ failed to reject wrong password", profile.username, profile.password);
    }
    
}
@end
