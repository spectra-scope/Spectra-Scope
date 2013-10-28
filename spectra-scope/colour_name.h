#ifndef COLOUR_NAME
#define COLOUR_NAME
enum colour{
	RED, GREEN, BLUE,
	MAGENTA, CYAN, YELLOW,
	PURPLE, ORANGE,
	BLACK, GREY, WHITE
};
enum colour colour_name(int r, int g, int b);
char const * colour_string(enum colour c);
#endif