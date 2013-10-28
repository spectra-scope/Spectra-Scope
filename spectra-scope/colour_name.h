//
//  colour_name.h
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-09-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//
#ifndef COLOUR_NAME
#define COLOUR_NAME
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
#endif