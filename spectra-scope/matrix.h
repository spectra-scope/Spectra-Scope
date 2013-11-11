//
//  matrix.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 13-11-04.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#ifndef matrix_h
#define matrix_h

/* matrix multiplication for square matrix arranged in row major order*/
void mat_mul(float * restrict dst, float const * restrict a, float const * restrict b, unsigned size);

#endif
