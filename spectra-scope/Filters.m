//
//  Filters.m
//  spectra-scope
//
//  Created by tt on 13-11-06.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#import "Filters.h"
struct mat4x4 const identityMatrix4 = {{
    1.0, 0, 0, 0,
    0, 1.0, 0, 0,
    0, 0, 1.0, 0,
    0, 0, 0, 1.0
}},
redGreenDefficiencyMatrix = {{
    0.5, 0.5, 0, 0,
    0.5, 0.5, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
}},
markGreenMatrix = {{
    -0.7, 1.0, -0.7, 0,
    -0.7, 1.0, -0.7, 0,
    0.3, 0, 0.3, 0,
    0, 0, 0, 1
}},
markRedMartix = {{
    1.0, -0.6, 0, 0,
    1.0, -0.7, -0.6, 0,
    0, 1.0, 0.3, 0,
    0, 0, 0, 1
}},
brightenGreenMatrix = {{
    1, 0, 0, 0,
    -0.15, 1.3, -0.15, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
}},
brightenRedMatrix = {{
    1.3, -0.15, -0.15, 0,
    0, 1, 0, 0,
    0, 0, 1, 0,
    0, 0, 0, 1
}};
GPUMatrix4x4 GPUMatrix4x4FromArray(float const * a)
{
    return (GPUMatrix4x4){
        {a[0], a[1], a[2], a[3]},
        {a[4], a[5], a[6], a[7]},
        {a[8], a[9], a[10], a[11]},
        {a[12], a[13], a[14], a[15]}
    };
}
@implementation Filters

@end
