//
//  ArcBuffer.m
//  spectra-scope
//
//  Created by tt on 13-11-06.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "ArcBuffer.h"

@implementation ArcBuffer

-(ArcBuffer *)initWithSize:(size_t)size{
    self = [super init];
    if(self != nil)
    {
        _size = size;
        _head = calloc(1, size);
    }
    return self;
}
-(void)dealloc{
    free(_head);
}
@end
