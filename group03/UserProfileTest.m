//
//  UserProfileTest.m
//  spectra-scope
//
//  Created by tt on 13-10-27.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "UserProfileTest.h"
#import "UserProfile.h"
@implementation UserProfileTest
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}
-(void)testSignup{
    UserProfile * profile = [[UserProfile alloc] init];
    profile.username = @"a";
    if([profile signUpWasSuccessful])
        STFail(@"sign up failed to reject existing username");
}
- (void)testAuthentication
{
    //STFail(@"Unit tests are not implemented yet in group03");
    
}
@end
