//
//  ArcBuffer.h
//  spectra-scope
//
//  Created by tt on 13-11-06.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArcBuffer : NSObject
-(ArcBuffer *)initWithSize:(size_t)size;
-(char*)head;
@end
