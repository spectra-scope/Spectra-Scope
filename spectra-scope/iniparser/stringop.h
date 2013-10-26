/*Copyright (c) <2013>, <Tian Lin Tan>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditionsare met:

1.	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
2.	Redistributions in binary form must reproduce the above copyright
	notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef STRINGOP_H
#define STRINGOP_H
#include <stdbool.h>
/* removes trailing whitespaces*/
void cstr_chomp(char * cstr);

bool cstr_has(char const * cstr, char c);

/* string substitution.
all occurrences of a is changed to b.
make sure cstr has enough space.*/
void cstr_subst(char * restrict cstr, char const * restrict a, char const * restrict b);

/* converts a string to an int.
intptr: the int pointed to by this pointer will be set to the converted value.

returns:
- zero for success
- non-zero for failure*/
int cstr2int(char const *, int * intptr);
int cstr2uint(char const *, unsigned * uintptr);
double cstr2double(char const *, char const ** endptr);

/* make a new copy of a char array string*/
char * cstr_dup(char const *);

/* checks if a char is whitespace*/
int is_whitespace(char c);

/* checks if a string is represents a valid int*/
int is_int(char const * cstr);
#endif // STRINGOP_H
