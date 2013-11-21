//
//  UserProfile.m
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-10-26.
//  Copyright (c) 2013 spectra. All rights reserved.
//

/*
 revisions:
 1.0: by Tian Lin Tan
 - added sign up functions
 1.1: by Tian Lin Tan
 - added log in functions
 */
#import "UserProfile.h"


NSString const * const sexNames[] = {
    [SEX_NONE] = @"none",
    [SEX_MALE] = @"male",
    [SEX_FEMALE] = @"female",
    [SEX_OTHER] = @"other"
};
enum sex string2sex(NSString * str)
{
    if([str isEqualToString:@"none"])
        return SEX_NONE;
    else if([str isEqualToString:@"male"])
        return SEX_MALE;
    else if([str isEqualToString:@"female"])
        return SEX_FEMALE;
    else if([str isEqualToString:@"other"])
        return SEX_OTHER;
    else
        return SEX_LAST;
}
BOOL string2bool(NSString * str)
{
    return [str isEqual:@"true"];
}
enum signup_status{
    SU_NONE,
    SU_SUCCESS,
    SU_CONFLICT,
    SU_FAIL
};

enum login_status{
    LI_NONE,
    LI_SUCCESS,
    LI_FAIL
};
@interface UserProfile ()
{
    enum signup_status signup_status;
    enum login_status login_status;
}
@end

@implementation UserProfile
-(id) init{
    self = [super init];
    if(self)
    {
        _username = @"";
        _password = @"";
        _continent = @"";
        _age = 0;
        _sex = SEX_NONE;
        signup_status = SU_NONE;
        login_status = LI_NONE;
    }
    return self;
}
-(void) signup:(struct ini*) profiles{
    char const * username = [_username UTF8String];
    if(ini_get(profiles, username, "password") != NULL)
    {
        signup_status = SU_CONFLICT;
    }
    else
    {
        ini_set(profiles, username, "password", [_password UTF8String]);
        assert(ini_get(profiles, username, "password"));
        
        ini_set(profiles, username, "continent", [_continent UTF8String]);
        assert(ini_get(profiles, username, "continent"));
        
        NSString * ageString = [NSString stringWithFormat:@"%d", _age];
        ini_set(profiles, username, "age", [ageString UTF8String]);
        assert(ini_get(profiles, username, "age"));
        
        ini_set(profiles, username, "sex", [sexNames[_sex] UTF8String]);
        assert(ini_get(profiles, username, "sex"));
        
        ini_set(profiles, username, "upload", "false");
        assert(ini_get(profiles, username, "upload"));
        
        signup_status = SU_SUCCESS;
    }
}
-(BOOL) signupWasSuccessful{
    return signup_status == SU_SUCCESS;
}

-(NSString *) signupStatusString{
    switch(signup_status){
        case SU_NONE:
            return @"no sign up performed";
        case SU_SUCCESS:
            return @"success";
        case SU_CONFLICT:
            return @"username already exists";
        case SU_FAIL:
            return @"something very wrong happened";
    }
}
-(void) login:(struct ini*)profiles{
    char const * username = [_username UTF8String];
    char const * password = ini_get(profiles, username, "password");
    if(password == NULL)
    {
        login_status = LI_FAIL;
    }
    else if(strcmp(password, [_password UTF8String]) != 0)
    {
        login_status = LI_FAIL;
    }
    else
    {
        NSLog(@"%p %p %p %p", ini_get(profiles, username, "continent"), ini_get(profiles, username, "age"), ini_get(profiles, username, "sex"), ini_get(profiles, username, "upload"));

        //_continent = [NSString stringWithUTF8String:ini_get(profiles, username, "continent")];
        _age = [[NSString stringWithUTF8String:ini_get(profiles, username, "age")] intValue];
        _sex = string2sex([NSString stringWithUTF8String:ini_get(profiles, username, "sex")]);
        _allowUploadUsageData = string2bool([NSString stringWithUTF8String:ini_get(profiles, username, "upload")]);

        login_status = LI_SUCCESS;
    }
}
-(BOOL) loginWasSuccessful{
    return login_status == LI_SUCCESS;
}
-(NSString *)loginStatusString{
    switch(login_status){
        case LI_NONE:
            return @"no login performed";
        case LI_SUCCESS:
            return @"successful login";
        case LI_FAIL:
            return @"username-password pair does not exist";
    }
}

-(void) update:(struct ini *)profiles{
    ini_set(profiles, [_username UTF8String], "upload", (_allowUploadUsageData ? "true" : "false"));
    assert(ini_get(profiles, [_username UTF8String], "upload"));
}
@end