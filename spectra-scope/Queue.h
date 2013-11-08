//
//  Queue.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 11/7/13.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Queue : NSObject
-(id) init;
-(BOOL)isEmpty;
-(id)top;
-(void)pull;
-(void)push:(id)item;
@end
