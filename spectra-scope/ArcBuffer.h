//
//  ArcBuffer.h
//  spectra-scope
//
//  Created by tt on 13-11-06.
//  Copyright (c) 2013 spectra. All rights reserved.
//

/* ArcBuffer is a wrapper class for calloc, in ARC enabled projects.*/
#import <Foundation/Foundation.h>
@interface ArcBuffer : NSObject

@property(readonly) void * head;
@property(readonly) size_t size;

-(ArcBuffer *)initWithSize:(size_t)size;
@end
