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
#include "ringbuffer.h"
/* maps rgb values to a basic colour name
 */
enum colour colour_id(int r, int g, int b)
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
	else if(abs(r - g) + abs(g - b) < 30)
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

enum brightness brightness_id(unsigned r, unsigned g, unsigned b)
{
    unsigned brightness = (r + g + b) / 3;
    if(brightness > 200)
        return VERY_BRIGHT;
    else if(brightness > 120)
        return BRIGHT;
    else if(brightness > 70)
        return MEDIUM;
    else if(brightness > 30)
        return DARK;
    else
        return VERY_DARK;
}
static char const * brightness_table[] = {
    [VERY_BRIGHT] = "very bright",
    [BRIGHT] = "bright",
    [MEDIUM] = "medium",
    [DARK] = "dark",
    [VERY_DARK] = "very dark"
};
char const * brightness_string(enum brightness b)
{
    return brightness_table[b];
}
unsigned pixel_dif(pixel_t a, pixel_t b)
{
    int ar = a.r, ag = a.g, ab = a.b;
    int br = b.r, bg = b.g, bb = b.b;
    return abs(ar - br) + abs(ag - bg) + abs(ab - bb);
}

pixel_t colour_average(pixel_t * pixels, unsigned width, unsigned height, unsigned x, unsigned y, unsigned local_tolerance, unsigned global_tolerance, unsigned queue_size)
{
    pixel_t startPixel = pixels[width * y + x];
    unsigned rAvg = startPixel.r;
    unsigned gAvg = startPixel.g;
    unsigned bAvg = startPixel.b;
    
    struct point{unsigned x, y;} startPoint = {x, y};
    struct ringbuffer queue = ringbuffer_create(queue_size, sizeof(struct point));
    char * visited = calloc(width * height, 1);
    ringbuffer_enq(&queue, &startPoint);
    while(queue.len > 0)
    {
        struct point p;
        ringbuffer_top(&queue, &p);
        ringbuffer_deq(&queue);
        struct point neighbors[4] = {
            {p.x - 1, p.y}, {p.x, p.y + 1}, {p.x + 1, p.y}, {p.x, p.y - 1}
        };
        for(int i = 0; i < 4; i++)
        {
            if(!((neighbors[i].x >= width || neighbors[i].y >= height) ||
                 (visited[neighbors[i].y * width + neighbors[i].x])))
            {
                visited[neighbors[i].y * width + neighbors[i].x] = 1;
                pixel_t current = pixels[p.y * width + p.x];
                pixel_t neighbor = pixels[neighbors[i].y * width + neighbors[i].x];
                unsigned global_dif = pixel_dif(startPixel, neighbor);
                unsigned local_dif = pixel_dif(current, neighbor);
                if(global_dif < global_tolerance && local_dif < local_tolerance && queue.len < queue.size)
                    ringbuffer_enq(&queue, neighbors + i);
            }
        }
        pixel_t current = pixels[p.y * width + p.x];
        rAvg = (rAvg * 7 + current.r) / 8;
        gAvg = (gAvg * 7 + current.g) / 8;
        bAvg = (bAvg * 7 + current.b) / 8;
    }
    return (pixel_t){.r = rAvg, .b = bAvg, .g = gAvg, .a = 255};
}