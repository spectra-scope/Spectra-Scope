//
//  colour_name.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-09-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//
#ifndef COLOUR_NAME
#define COLOUR_NAME
#include <stdint.h>
enum colour{
	RED, GREEN, BLUE,
	MAGENTA, CYAN, YELLOW,
	PURPLE, ORANGE,
	BLACK, GREY, WHITE
};



// get the identity of a colour (red, green, blue, etc.)
enum colour colour_name(int r, int g, int b);

// get a string for printing out a colour identity
char const * colour_string(enum colour c);

enum brightness{
    VERY_DARK, DARK,
    MEDIUM,
    BRIGHT, VERY_BRIGHT
};

enum brightness brightness_id(unsigned r, unsigned g, unsigned b);
char const * brightness_string(enum brightness b);

typedef struct{
    uint32_t r:8, g:8, b:8, a:8;
} pixel_t;
unsigned pixel_dif(pixel_t a, pixel_t b);
#endif