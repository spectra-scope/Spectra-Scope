//
//  UserProfile.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-10-26.
//  Copyright (c) 2013 spectra. All rights reserved.
//
/*
 revisions:
 1.0: by Tian Lin Tan
 - added enum sex
 - added fields for profile
 - added sign up function declarations
 1.1: by Tian Lin Tan
 - added log in function declarations
 */
#import <Foundation/Foundation.h>
#import "iniparser.h"

/* a list of all available sexes*/
enum sex{
    SEX_NONE,
    SEX_MALE,
    SEX_FEMALE,
    SEX_OTHER,
    SEX_LAST
};

// maps enum sex to NSString*
extern NSString const * const sexNames[];

@interface UserProfile : NSObject
@property(strong, nonatomic) NSString * username;
@property(strong, nonatomic) NSString * password;

// this is the name of the user's continent of origin
@property(strong, nonatomic) NSString * continent;

// this is the user's biological sex
@property enum sex sex;

@property unsigned age;

@property BOOL allowUploadUsageData;


-(id) init;
-(void) signup:(struct ini*) profiles;
-(BOOL) signupWasSuccessful;
-(NSString*) signupStatusString;

-(void) login:(struct ini*)profiles;
-(BOOL) loginWasSuccessful;
-(NSString*) loginStatusString;

-(void) update:(struct ini *)profiles;
@end
