//
//  matrix.c
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-04.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#include "matrix.h"
void mat_mul(float * restrict dst, float const * restrict a, float const * restrict b, unsigned size)
{
    for(unsigned y = 0; y < size; y++)
    {
        for(unsigned x = 0; x < size; x++)
        {
            dst[y * size + x] = 0;
            for(unsigned i = 0; i < size; i++)
            {
                dst[y * size + x] += a[y * size + i] * b[i * size + x];
            }
        }
    }
}