//
//  UserProfile.m
//  spectra-scope
//
//  Created by tt on 13-10-26.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "UserProfile.h"
#import "iniparser/iniparser.h"
#define PROFILE_FILE "profiles"

struct ini * profiles = NULL;

void createProfileFileIfNotExist(void)
{
    FILE * fid;
    fid = fopen(PROFILE_FILE, "r");
    if(fid == NULL)
    {
        fid = fopen(PROFILE_FILE, "w");
        if(fid != NULL)
            fclose(fid);
    }
}
void loadProfileIniIfNotLoaded(void)
{
    if(profiles == NULL)
    {
        createProfileFileIfNotExist();
        FILE * fid = fopen(PROFILE_FILE, "rb");
        if(fid == NULL)
        {
            fputs("unable to create profile file", stderr);
            return;
        }
        profiles = ini_new();
        if(profiles == NULL)
        {
            fputs("unable to create profile object", stderr);
            return;
        }
        ini_read(profiles, fid);
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