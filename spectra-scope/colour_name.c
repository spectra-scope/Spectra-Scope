#include "colour_name.h"
#include <stdlib.h>
enum colour colour_name(int r, int g, int b)
{
	int brightness = (r + g + b) / 3;
	if(brightness > 240)
		return WHITE;
	else if(brightness < 15)
		return BLACK;
	else if(abs(r - g) < 15 && abs(g - b) < 15)
		return GREY;

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
	else if(r > b && b > g)
	{
		if((r * 3) / (b * 2) > 1)
			return RED;
		else
			return MAGENTA;
	}
	
	else
		return GREY;
}
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