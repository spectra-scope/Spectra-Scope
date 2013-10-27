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
#include "iniparser.h"
#include "hashsetv.h"
#include "varstr.h"
#include "stringop.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

// ini ini char reader
struct char_stream{
	int c;
	int escaped;
	unsigned row, col;
	FILE * fid;
	int end;
};
static struct char_stream * char_stream_new(FILE * fid)
{
	struct char_stream * cs = calloc(1, sizeof *cs);
	if(cs != NULL && fid != NULL)
	{
		cs->c = -1;
		cs->escaped = 0;
		cs->row = 1;
		cs->col = 0;
		cs->end = feof(fid);
		cs->fid = fid;
	}
	else
	{
		free(cs);
		cs = NULL;
	}
	return cs;
}
void char_stream_del(struct char_stream * cs)
{
	if(cs != NULL)
	{
		cs->fid = 0;
		free(cs);
	}
}
static int next_char(struct char_stream * stream)
{
	if(!stream->end)
	{
		int escape = 0;
		do{
			int c = fgetc(stream->fid);
			if(c == EOF)
			{
				stream->c = EOF;
				stream->end = 1;
				break;
			}
			else if(c == '\n')
			{
				stream->row++;
				stream->col = 1;
			}
			else
				stream->col++;
	
			if(!escape)
			{
				if(c != '\\')
				{
					stream->c = c;
					stream->escaped = 0;
					break;
				}
				else
					escape = 1;
			}
			else
			{
				if(c == '\n')
					continue;	
				else if(c == 'n')
					stream->c = '\n';
				else if(c == 't')
					stream->c = '\t';
				else if(c == 's')
					stream->c = ' ';
				else if(c == 'b')
					stream->c = '\b';
				else if(c == 'r')
					stream->c = '\r';
				else
					stream->c = c;
				stream->escaped = 1;
				break;
			}
		}while(1);
	}
	return stream->c;
}
static int char_is_name(struct char_stream * cs)
{
	int c = cs->c;
	return ((c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		(c >= '0' && c <= '9') ||
		(c == '_')) && !cs->escaped;
}
enum token_type{
	TOKEN_TYPE_SECTION,
	TOKEN_TYPE_NAME,
	TOKEN_TYPE_ASSIGNMENT,
	TOKEN_TYPE_STRING,
	TOKEN_TYPE_NEWLINE
};
struct token{
	enum token_type type;
	char * text;
};
static struct token * token_new(void)
{
	struct token * newtok = calloc(1, sizeof(struct token));
	if(newtok != NULL)
	{
		newtok->type = TOKEN_TYPE_NEWLINE;
		newtok->text = NULL;
	}
	return newtok;
}
static void token_del(struct token * tok)
{
	if(tok)
	{
		free(tok);
	}
}
// token stream gives one token every time it is read
struct token_stream{
	struct char_stream * cs;
	int next_state;
	int end;
};
struct token_stream * token_stream_new(FILE * fid)
{
	struct char_stream * cs = char_stream_new(fid);
	struct token_stream * ts = calloc(1, sizeof *ts);
	if(cs != NULL && ts != NULL)
	{
		ts->cs = cs;
		ts->next_state = 0;
		ts->end = 0;
	}
	else
	{
		free(ts);
		ts = NULL;
		char_stream_del(cs);
	}
	return ts;
}
static void token_stream_del(struct token_stream * ts)
{
	if(ts != NULL)
	{
		char_stream_del(ts->cs);
		ts->cs = NULL;
		free(ts);
	}
}
static struct token * next_token(struct token_stream * ts)
{
	if(ts->end)
		return NULL;
	enum states{
		READ_NEXT = 0,
		SCAN, SCAN_ERR,
		BUILD_SECTION, BUILD_SECTION1, BUILD_SECTION_END,
		BUILD_NAME, BUILD_NAME1, BUILD_NAME_END,
		BUILD_ASSIGNMENT,
		BUILD_STRING, BUILD_STRING1, BUILD_STRING_END,
		BUILD_COMMENT,
		BUILD_NEWLINE,
		BUILD_END,
		ERROR,
		SKIP_LINE,
	} state = ts->next_state;
	
	struct varstr * buf = varstr_new();
	struct char_stream * cs = ts->cs;
	struct token * tok = NULL;
	int running = 1;
	do switch(state){
	case READ_NEXT:
		next_char(cs);
		
		state = SCAN;
	case SCAN:
		if(!cs->escaped)
		{
			if(cs->c == ' ' || cs->c == '\t')
				state = READ_NEXT;
			else if(cs->c == '[')
				state = BUILD_SECTION;
			else if(char_is_name(cs))
				state = BUILD_NAME;
			else if(cs->c == '=')
				state = BUILD_ASSIGNMENT;
			else if(cs->c == '"')
				state = BUILD_STRING;
			else if(cs->c == '#')
				state = BUILD_COMMENT;
			else if(cs->c == '\n')
				state = BUILD_NEWLINE;
			else if(cs->c == EOF)
				state = BUILD_END;
			else
				state = SCAN_ERR;
		}
		else
			state = SCAN_ERR;
		break;
	case SCAN_ERR:
		fprintf(stderr,"next_token: "
			"bad token at row %d, column %d\n",
			cs->row, cs->col);
		state = SKIP_LINE;
		break;

	case BUILD_SECTION:
		// [section]
		varstr_clear(buf);
		tok = token_new();
		tok->type = TOKEN_TYPE_SECTION;
		state = BUILD_SECTION1;
	case BUILD_SECTION1:
		next_char(cs);
		if(char_is_name(cs))
			varstr_append(buf, cs->c);
		else
			state = BUILD_SECTION_END;
		break;
	case BUILD_SECTION_END:
		if(cs->c == ']' && !cs->escaped)
		{
			ts->next_state = READ_NEXT;
			tok->text = cstr_dup(varstr_view(buf));
			running = 0;
		}
		else
		{
			fprintf(stderr, "next_token: "
				"bad section name at row %d, column %d, "
				"expected ']'\n",
				cs->row, cs->col);
			state = ERROR;
		}
		break;
	case BUILD_NAME:
		// name
		tok = token_new();
		tok->type = TOKEN_TYPE_NAME;
		varstr_clear(buf);
		varstr_append(buf, cs->c);
		state = BUILD_NAME1;
	case BUILD_NAME1:
		next_char(cs);
		if(char_is_name(cs))
			varstr_append(buf, cs->c);
		else
			state = BUILD_NAME_END;
		break;
	case BUILD_NAME_END:
		ts->next_state = SCAN;
		tok->text = cstr_dup(varstr_view(buf));
		running = 0;
		break;
	case BUILD_ASSIGNMENT:
		// =
		tok = token_new();
		tok->type = TOKEN_TYPE_ASSIGNMENT;
		ts->next_state = READ_NEXT;
		running = 0;
		break;
	case BUILD_STRING:
		/* "multi
			line
				string
					with escape /"/n"
		*/
		tok = token_new();
		tok->type = TOKEN_TYPE_STRING;
		varstr_clear(buf);
		state = BUILD_STRING1;
	case BUILD_STRING1:
		next_char(cs);
		if(cs->c == EOF)
			state = BUILD_STRING_END;
		else if(cs->c == '"' && !cs->escaped)
			state = BUILD_STRING_END;
		else
			varstr_append(buf, cs->c);
		break;
	case BUILD_STRING_END:
		if(cs->c == '"' && !cs->escaped)
		{
			ts->next_state = READ_NEXT;
			tok->text = cstr_dup(varstr_view(buf));
			running = 0;
		}
		else if(cs->c == EOF)
		{
			fprintf(stderr, "next_token"
				"bad string at row %d, column %d, "
				"expected '\"'\n",
				cs->row, cs->col);
			state = ERROR;
		}
		break;
	case BUILD_COMMENT:
		// # comment
		state = SKIP_LINE;
		break;
	case BUILD_NEWLINE:
		tok = token_new();
		tok->type = TOKEN_TYPE_NEWLINE;
		ts->next_state = READ_NEXT;
		running = 0;
		break;
	case BUILD_END:
		tok = token_new();
		tok->type = TOKEN_TYPE_NEWLINE;
		ts->end = 1;
		running = 0;
		break;
	case ERROR:
		token_del(tok);
		tok = NULL;
		state = SKIP_LINE;
	case SKIP_LINE:
		if(cs->c == '\n' && !cs->escaped)
			state = BUILD_NEWLINE;
		else if(cs->c == EOF)
			state = BUILD_END;
		else
			next_char(cs);
		break;
	}while(running);
	varstr_del(buf);
	return tok;
}

/*
here are all the possible commands.
*/
enum command_name{
	SET_SECTION,
	INSERT_PAIR
};

/*
Command objects are consumed by the ini reader to build an in-memory
version of the file.
*/
struct command{
	enum command_name type;
	char * arg1;
	char * arg2;
};
static struct command * command_new(void)
{
	return calloc(1, sizeof(struct command));
}
static void command_del(struct command * com)
{
	if(com != NULL)
	{
		com->arg1 = NULL;
		com->arg2 = NULL;
		free(com);
	}
}

/*
The command stream object is used to produce a stream of commands.
It consumes tokens generated by a token stream.
*/
struct command_stream{
	struct token_stream * ts;
	int next_state;
	int end;
};

/*
Creates a new command stream from an open file stream with read permission.
*/
static struct command_stream * command_stream_new(FILE * fid)
{
	struct token_stream * ts = token_stream_new(fid);
	struct command_stream * cs = calloc(1, sizeof * cs);
	if(ts != NULL && cs != NULL)
	{
		cs->ts = ts;
		cs->next_state = 0;
		cs->end = 0;
	}
	else
	{
		free(cs);
		cs = NULL;
		token_stream_del(ts);
	}
	return cs;
}
static void command_stream_del(struct command_stream * cs)
{
	if(cs != NULL)
    {
        token_stream_del(cs->ts);
        free(cs);
    }
}
/*
This function is the core of the command stream.
It consumes a stream of tokens, and produces a stream of commands.
*/
static struct command * next_command(struct command_stream * cs)
{
	enum states{
		READ_NEXT,
		SCAN,
		BUILD_SET_SECTION,
		BUILD_INSERT_PAIR,
		BUILD_END,
		ERROR,
		SKIP_LINE,
	} state = cs->next_state;
	
	struct token_stream * ts = cs->ts;
	struct token * tok = NULL;
	struct command * com = NULL;
	
	do switch(state){
	case READ_NEXT:
		tok = next_token(ts);
		state = SCAN;
	case SCAN:
		if(tok == NULL)
			state = BUILD_END;
		else if(tok->type == TOKEN_TYPE_SECTION)
			state = BUILD_SET_SECTION;
		else if(tok->type == TOKEN_TYPE_NAME)
			state = BUILD_INSERT_PAIR;
		else if(tok->type == TOKEN_TYPE_NEWLINE)
			state = READ_NEXT;
		else
			state = SKIP_LINE;
		break;
	case BUILD_SET_SECTION:
		com = command_new();
		com->type = SET_SECTION;
		com->arg1 = tok->text;
		tok->text = NULL;
		token_del(tok);
		tok = NULL;

		tok = next_token(ts);
		assert(tok != NULL);
		if(tok->type == TOKEN_TYPE_NEWLINE)
		{
			token_del(tok);
			cs->next_state = READ_NEXT;
			return com;
		}
		else
			state = ERROR;
		break;
	case BUILD_INSERT_PAIR:
		com = command_new();
		com->type = INSERT_PAIR;
		com->arg1 = tok->text;
		tok->text = NULL;
		token_del(tok);
		tok = NULL;

		tok = next_token(ts);
		assert(tok != NULL);
		if(tok->type == TOKEN_TYPE_ASSIGNMENT)
		{
			token_del(tok);
			tok = NULL;
		}
		else
		{
			state = ERROR;
			break;
		}

		tok = next_token(ts);
		assert(tok != NULL);
		if(tok->type == TOKEN_TYPE_NAME || tok->type == TOKEN_TYPE_STRING)
		{
			com->arg2 = tok->text;
			tok->text = NULL;
			token_del(tok);
			tok = NULL;
		}
		else
		{
			state = ERROR;
			break;
		}

		tok = next_token(ts);
		assert(tok != NULL);
		if(tok->type == TOKEN_TYPE_NEWLINE)
		{
			cs->next_state = READ_NEXT;
			return com;
		}
		else
		{
			state = ERROR;
		}
		break;
	case BUILD_END:
		cs->end = 1;
		cs->next_state = BUILD_END;
		return NULL;
	case ERROR:
		if(com != NULL)
		{
			free(com->arg1);
			free(com->arg2);
			command_del(com);
			com = NULL;
		}
		state = SKIP_LINE;
	case SKIP_LINE:
		if(tok->type == TOKEN_TYPE_NEWLINE)
		{
			token_del(tok);
			state = READ_NEXT;
		}
		else
		{
			token_del(tok);
			tok = next_token(ts);
		}
		break;
	}while(1);
}

/*
A structure to represent a key and value pair.
For ini file, value can either be a section table or a string.
This structure will be stored in hash sets to emulate hash tables.
Think of it as a tuple in a relational database table.
*/
struct entry{
	char * name;
	void * val;
};

/*
The name field is used to identify a pair.
Think of name as a primary key in a relational databse table.
*/
static int entry_cmp(void const * a, void const * b)
{
	struct entry const * e1 = a;
	struct entry const * e2 = b;
	return strcmp(e1->name, e2->name);
}
/*
This is a simple hash function for the hash sets.
*/
static unsigned entry_hash(void const * a)
{
	unsigned sum = 0;
	char const * s = ((struct entry *)a)->name;
	while(*s)
		sum = (sum * 31) + *s++;
	return sum;
}

/*
A structure to represent an ini object.
*/
struct ini{
	struct hashset * symtable;
};

/*
Create an empty ini object.
*/
struct ini * ini_new(void)
{
	struct ini * ini = calloc(1, sizeof *ini);
	struct hashset * hs =
		hashset_new(sizeof(struct entry), &entry_cmp, &entry_hash);
	if(ini != NULL && hs != NULL)
	{
		ini->symtable = hs;
	}
	else
	{
		free(ini);
		ini = NULL;
		hashset_del(hs);
	}
	return ini;
}
/*
Frees all memory used by this ini object.
The algorithm is described by the following pseudo code:
for each section s in ini
	for each pair p in section s
		free p
	free s
free ini
*/
void ini_del(struct ini * ini)
{
	if(ini != NULL)
	{
		struct hashset_iter * section_iter = hashset_iter_new(ini->symtable);
		while(hashset_iter_next(section_iter))
		{
			struct entry const * section = hashset_iter_get(section_iter);
			struct hashset * section_table = section->val;
			struct hashset_iter * val_iter = hashset_iter_new(section_table);
			
			while(hashset_iter_next(val_iter))
			{
				struct entry const * pair = hashset_iter_get(val_iter);
				free(pair->name);
				free(pair->val);
			}
			hashset_iter_del(val_iter);
			hashset_del(section->val);
			free(section->name);
		}
		hashset_iter_del(section_iter);
		hashset_del(ini->symtable);
		free(ini);
	}
}

/*
reads in a stream of commands, and insert pairs or create tables depending
on the command.
*/
int ini_read(struct ini * ini, FILE * fid)
{
	if(ini == NULL || fid == NULL)
		return -1;
	struct hashset * section_table = NULL;
	struct command_stream * cs = command_stream_new(fid);
    if(cs == NULL)
        return -1;
	struct command * com = command_new();
	com->type = SET_SECTION;
	com->arg1 = calloc(1, 1);
	while(com != NULL)
	{
		if(com->type == SET_SECTION)
		{
			struct entry key = {.name = com->arg1};
			struct entry * section = hashset_get(ini->symtable, &key);
			if(section == NULL)
			{
				struct entry new_section = {
					.name = cstr_dup(com->arg1),
					.val = hashset_new(sizeof(struct entry), &entry_cmp, &entry_hash)
				};
				hashset_insert(ini->symtable, &new_section);
				section_table = new_section.val;
			}
			else
			{
				section_table = section->val;
			}
			free(com->arg1);
		}
		else if(com->type == INSERT_PAIR)
		{
			struct entry key = {.name = com->arg1};
			struct entry * ret = hashset_get(section_table, &key);
			if(ret != NULL)
			{
				struct entry old = *ret;
				hashset_remove(section_table, ret);
				free(old.name);
				free(old.val);
			}
			struct entry e = {
				.name = cstr_dup(com->arg1),
				.val = cstr_dup(com->arg2)
			};
			hashset_insert(section_table, &e);
			
			free(com->arg1);
			free(com->arg2);
		}
		command_del(com);
		com = NULL;
		com = next_command(cs);
	}
    command_stream_del(cs);
	return 0;
}
void ini_write(struct ini * ini, FILE * fid)
{
	struct hashset_iter * section_iter = hashset_iter_new(ini->symtable);
	while(hashset_iter_next(section_iter))
	{
		struct entry const * section = hashset_iter_get(section_iter);
		struct hashset * section_table = section->val;
		struct hashset_iter * val_iter = hashset_iter_new(section_table);
		
		fprintf(fid, "[%s]\n", section->name);
		while(hashset_iter_next(val_iter))
		{
			struct entry const * pair = hashset_iter_get(val_iter);
			fprintf(fid, "%s=%s\n", pair->name, pair->val);
		}
		hashset_iter_del(val_iter);
	}
	hashset_iter_del(section_iter);
}

char const * ini_get(struct ini const * ini,
	char const * section, char const * name)
{
	if(section == NULL)
		section = "";
	struct entry * ret = NULL;
	{
		struct entry key = {.name = (char*)section};
		ret = hashset_get(ini->symtable, &key);
	}
	if(ret != NULL)
	{
		struct entry key = {.name = (char*)name};
		ret = hashset_get(ret->val, &key);
	}
	if(ret != NULL)
		return ret->val;
	else
		return NULL;
}
int ini_set(struct ini * ini, char const * section_name, char const * name, char const * val)
{
	
	struct hashset * section_table = NULL;
	// first find the section
	{
		struct entry key = {.name = (char*)section_name};
		struct entry * section = hashset_get(ini->symtable, &key);
		if(section != NULL)
			section_table = section->val;
	}
	
	// create section if it doesn't exist
	if(section_table == NULL)
	{
		section_table = hashset_new(sizeof(struct entry), &entry_cmp, &entry_hash);
		struct entry pair = {
			.name = cstr_dup(section_name),
			.val = section_table
		};
		hashset_insert(ini->symtable, &pair);
	}
	
	// then find key value pair in section
	struct entry * pair = NULL;
	{
		struct entry key = {.name = (char*)name};
		pair = hashset_get(section_table, &key);
	}
	
	// insert key value pair if pair doesn't exist
	if(pair == NULL)
	{
		struct entry new_pair = {
			.name = cstr_dup(name),
			.val = cstr_dup(val)
		};
		hashset_insert(section_table, &new_pair);
	}
	// otherwise set value
	else
	{
		free(pair->val);
		pair->val = cstr_dup(val);
	}
	return 0;
}
