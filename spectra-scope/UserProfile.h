//
//  UserProfile.h
//  spectra-scope
//
//  Created by tt on 13-10-26.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>


/* a list of all available sexes*/
enum sex{
    SEX_NONE,
    SEX_MALE,
    SEX_FEMALE,
    SEX_OTHER,
    SEX_LAST
};
extern NSString const * const sexNames[];
@interface UserProfile : NSObject



@property(strong, nonatomic) NSString * username;
@property(strong, nonatomic) NSString * password;
@property(strong, nonatomic) NSString * continent;
@property enum sex sex;
@property unsigned age;
-(id) init;
-(void) signUp;
-(BOOL) signUpWasSuccessful;
-(NSString*) signUpStatusString;

-(void) login;
-(BOOL) loginWasSuccessful;
-(NSString*) loginStatusString;
@end
