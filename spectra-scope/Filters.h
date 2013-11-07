//
//  Filters.h
//  spectra-scope
//
//  Created by tt on 13-11-06.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImage.h"
struct mat4x4{
    float entries[16];
};
extern struct mat4x4 const
identityMatrix4,
redGreenDefficiencyMatrix,
markGreenMatrix,
markRedMartix,
brightenGreenMatrix,
brightenRedMatrix;

GPUMatrix4x4 GPUMatrix4x4FromArray(float const * a);
@interface Filters : NSObject

@end
