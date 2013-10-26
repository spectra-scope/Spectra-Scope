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
#ifndef INIPARSER_H
#define INIPARSER_H
#include <stdio.h>

// ini file handle
struct ini;

// create new ini file handle
struct ini * ini_new(void);

// delete ini file handle
void ini_del(struct ini * ini);

// read from an input stream
int ini_read(struct ini * restrict ini, FILE * restrict fid);

// write ini file to output stream (unordered)
void ini_write(struct ini * restrict ini, FILE * restrict fid);



// get a value from ini file
char const * ini_get(struct ini const * restrict ini,
	char const * section,
	char const * name);

// set a value from ini file, create entry if it doesn't already exist
int ini_set(struct ini * restrict ini,
	char const * section_name,
	char const * name,
	char const * val);
#endif
