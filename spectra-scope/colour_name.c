//
//  colour_name.c
//  spectra-scope
//
//  Created by Tian Lin Tan on 2013-09-18.
//  Copyright (c) 2013 spectra. All rights reserved.
//

/*
 revisions:
 1.0: by Tian Lin Tan
 - added colour_name function and colour_string function
 2.0: by Tian Lin Tan
 - changed the way colours are mapped to rgb
 3.0: by Tian Lin Tan
 - changed the way colours are mapped to rgb
 */
#include "colour_name.h"
#include <stdlib.h>

/* maps rgb values to a basic colour name
 */
enum colour colour_name(int r, int g, int b)
{
    // brightness is the average of three components
	int brightness = (r + g + b) / 3;
    
    // if colours is very bright, it's white
	if(brightness > 240)
		return WHITE;
    
    // if colours is dark, it's black
	else if(brightness < 15)
		return BLACK;
    
    //if difference between the three components aren't a lot, it's grey
	else if(abs(r - g) < 15 && abs(g - b) < 15)
		return GREY;

    /* the next 6 cases maps colours based on the greatest component.
     the second greatest component is always greater than the smallest component
     to avoid division by zero.
     */
	else if(r >= g && g > b)
	{
		if((r * 2 ) / (g * 3) > 1)
			return RED;
		else if((r * 3 ) / (g * 2) > 1)
			return ORANGE;
		else
			return YELLOW;
	}
    
	else if(g >= r && r > b)
	{
		if((g * 3 ) / (r * 2) > 1)
			return GREEN;
		else
			return YELLOW;
	}
	else if(g >= b && b > r)
	{
		if((g * 3) / (b * 2) > 1)
			return GREEN;
		else
			return CYAN;
	}
	else if(b >= g && g > r)
	{
		if((b * 3) / (g * 2) > 1)
			return BLUE;
		else
			return CYAN;
	}
	else if(b >= r && r > g)
	{
		if((b * 2) / (r * 3) > 1)
			return BLUE;
		else if((b * 3) / (r * 2) > 1)
			return PURPLE;
		else
			return MAGENTA;
	}
	else if(r >= b && b > g)
	{
		if((r * 3) / (b * 2) > 1)
			return RED;
		else
			return MAGENTA;
	}
    
    // the next three cases are for strictly dominant components (i.e. one component greater than the other two)
	else if(r > g && r > b)
        return RED;
    else if(g > r && g > b)
        return GREEN;
    else if(b > r && b > g)
        return BLUE;
    
    // grey again as a catch all case
	else
		return GREY;
}

// maps basic colour enum to colour names in string
static char const * colour_table[] = {
	[WHITE] = "white",
	[GREY] = "grey",
	[BLACK] = "black",
	
	[RED] = "red",
	[GREEN] = "green",
	[BLUE] = "blue",
	
	[CYAN] = "cyan",
	[MAGENTA] = "magenta",
	[YELLOW] = "yellow",
	
	[PURPLE] = "purple",
	[ORANGE] = "orange"
};
char const * colour_string(enum colour c)
{
	return colour_table[c];
}