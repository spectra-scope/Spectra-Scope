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
#include "stringop.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>
#include <assert.h>

int char_to_int(char c)
{
	if(c >= '0' && c <= '9')
		return c - '0';
	if(c >= 'a' && c <= 'z')
		return c - 'a' + 10;
	if(c >= 'A' && c <= 'Z')
		return c - 'A' + 10;
	return -1;
}
bool cstr_has(char const * cstr, char c)
{
	while(*cstr != 0)
	{
		if(*cstr == c)
			return true;
		cstr++;
	}
	return false;
}
void cstr_remove_trailing(char * cstr, char const * charset)
{
	char * begin = cstr;
	while(cstr_has(charset, *begin))
		begin++;
	int i = 0;
	if(cstr != begin)
	{
		for(; begin[i] != 0; i++)
			cstr[i] = begin[i];
		cstr[i] = 0;
	}
	else
	{
		while(cstr[i] != 0)
			i++;
	}
	i--;
	while(i >= 0 && cstr_has(charset, cstr[i]))
		i--;
	cstr[i + 1] = 0;
}
void cstr_chomp(char * cstr)
{
	cstr_remove_trailing(cstr, " \t\n");
}
void cstr_subst(char * restrict cstr,
	char const * restrict a, char const * restrict b)
{
	char * iter = cstr;
	int const a_len = strlen(a);
	int const b_len = strlen(b);
	int const gap = abs(a_len - b_len);
	while(*iter != 0)
	{
		if(strncmp(iter, a, a_len) != 0)
		{
			iter++;
			continue;
		}
		/* expansion*/
		if(a_len < b_len)
		{
			memmove(iter + gap, iter, strlen(iter) + 1);
			memcpy(iter, b, b_len);
		}
		/* reduction*/
		else
		{
			memcpy(iter, b, b_len);
			iter += b_len;
			if(gap > 0)
				memmove(iter, iter + gap, strlen(iter) + 1);
		}
	}
}
int cstr2uint(char const * cstr, unsigned * uintptr)
{
	unsigned sum = 0;
	if(*cstr == 0)
		return -3;
	while(*cstr)
	{
		sum *= 10;
		unsigned digit = *cstr - '0';
		if(digit > 9)
			return -1;
		unsigned new_sum = sum + digit;
		if(new_sum < sum)
			return -2;
		sum = new_sum;
		cstr++;
	}
	*uintptr = sum;
	return 0;
}
int cstr2int(char const * cstr, int * intptr)
{
	if(*cstr == 0)
		return -3;
	int sign = 1;
	if(*cstr == '-')
	{
		sign = -1;
		cstr++;
	}
	unsigned magnitude;
	if(cstr2uint(cstr, &magnitude) != 0)
		return -1;
	int sum = (int)magnitude;
	if(sum < 0)
		return -2;
	*intptr = sum * sign;
	return 0;
}
double cstr2double(char const * cstr, char const ** endptr)
{
	char const * tmpendptr;
	double sign = 1;
	double num = 0;
	if(endptr == 0)
		endptr = &tmpendptr;
	
	while(*cstr == ' ' || *cstr == '\n' || *cstr == '\t')
		cstr++;
	
	if(*cstr == '-')
	{
		sign = -1;
		cstr++;
	}
	
	//build whole part
	while(1)
	{
		int c = *cstr;
		if(c >= '0' && c <= '9')
			num = num * 10 + (c - '0');
		else if(c == '.')
			break;
		else
		{
			*endptr = cstr;
			if(c == 0 || c == ' ' || c == '\n' || c == '\t')
				return sign * num;
			else
				return 0;
		}
		cstr++;
	}
	
	// skip decimal point
	cstr++;
	
	//scan decimal part
	while(1)
	{
		int c = *cstr;
		if(c >= '0' && c <= '9')
			cstr++;
		else
		{
			*endptr = cstr;
			if(c == 0 || c == ' ' || c == '\n' || c == '\t')
				break;
			else
				return 0;
		}
	}
	cstr--;
	// build decimal part
	while(*cstr != '.')
	{
		int c = *cstr;
		num = num + ((double)(c - '0')) * 0.1;
		cstr--;
	}
	return sign * num;
}

char * cstr_dup(char const * src)
{
	char * new_str = NULL;
	if(src)
	{
		unsigned len =
			(strlen(src) + sizeof(int)) / sizeof(int) * sizeof(int);
		new_str = calloc(len , 1);
		if(new_str)
			strcpy(new_str, src);
	}
	return new_str;
}
int is_whitespace(char c)
{
	return (c == '\n') || (c == ' ') || (c == '\t');
}
int is_int(char const * cstr)
{
	if(cstr == 0)
		return false;
	if(*cstr == 0)
		return false;
	for(int i = 0; cstr[i] == 0; i++)
	{
		if(cstr[i] < '0' || cstr[i] > '9')
		{
			if((i != 0) || (cstr[i] != '-' && cstr[i] != '+'))
				return false;
		}
	}
	return true;
}
