//
//  UserProfile.m
//  spectra-scope
//
//  Created by tt on 13-10-26.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "UserProfile.h"
#import "iniparser/iniparser.h"


NSString const * const sexNames[] = {
    [SEX_NONE] = @"none",
    [SEX_MALE] = @"male",
    [SEX_FEMALE] = @"female",
    [SEX_OTHER] = @"other"
};


struct ini * profiles = NULL;
NSString * getProfilePath(void)
{
    //get the documents directory:
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * dir = [paths objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/profiles.txt", dir];

}
void createProfileFileIfNotExist(void)
{
    NSString * profile_path = getProfilePath();
    puts([profile_path UTF8String]);
    FILE * fid;
    fid = fopen([profile_path UTF8String], "r");
    if(fid == NULL)
    {
        fid = fopen([profile_path UTF8String], "w");
        if(fid != NULL)
            fclose(fid);
        else
            perror("createpProfileFileIfNotExist");
    }
}
void loadProfileIniIfNotLoaded(void)
{
    if(profiles == NULL)
    {
        NSString * profile_path = getProfilePath();
        profiles = ini_new();
        assert(profiles != NULL);
        createProfileFileIfNotExist();
        FILE * fid = fopen([profile_path UTF8String], "rb");
        if(fid != NULL)
        {
            ini_read(profiles, fid);
            fclose(fid);
        }
        else
        {
            fputs("unable to create profile file", stderr);
            perror("loadProfileIniIfNotLoaded");
        }
    }
}
void storeProfileIni(void)
{
    if(profiles != NULL)
    {
        NSString * profile_path = getProfilePath();
        FILE * fid = fopen([profile_path UTF8String], "wb");
        if(fid != NULL)
        {
            ini_write(profiles, fid);
            fclose(fid);
        }
        else
            perror("storeProfileIni");
    }
}
struct ini * getProfileIni(void)
{
    loadProfileIniIfNotLoaded();
    if(profiles == NULL)
        abort();
    else
        return profiles;
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
        login_status = LI_FAIL;
    }
    return self;
}
-(void) signUp{
    struct ini * profiles = getProfileIni();
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
        
        char age[5];
        snprintf(age, sizeof age, "%d", _age);
        ini_set(profiles, username, "age", age);
        assert(ini_get(profiles, username, "age"));
        
        ini_set(profiles, username, "sex", [sexNames[_sex] UTF8String]);
        assert(ini_get(profiles, username, "sex"));
        
        storeProfileIni();
        signup_status = SU_SUCCESS;
    }
}
-(BOOL) signUpWasSuccessful{
    return signup_status == SU_SUCCESS;
}

-(NSString *) signUpStatusString{
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
-(void) login{
    struct ini * profiles = getProfileIni();
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

@end