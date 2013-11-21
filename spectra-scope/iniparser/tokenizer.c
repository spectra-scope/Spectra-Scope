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
#include "tokenizer.h"
#include "varstr.h"
#include "stringop.h"
#include <stdlib.h>
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


static struct token token_new(enum token_type type)
{
	return (struct token){
		.type = type,
		.text = NULL
	};
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
void token_stream_del(struct token_stream * ts)
{
	if(ts != NULL)
	{
		char_stream_del(ts->cs);
		ts->cs = NULL;
		free(ts);
	}
}
struct token token_stream_read(struct token_stream * ts)
{
	if(ts->end)
		return token_new(TOKEN_TYPE_END);
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
	struct token tok;
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
		tok = token_new(TOKEN_TYPE_SECTION);
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
			tok.text = cstr_dup(varstr_view(buf));
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
		tok = token_new(TOKEN_TYPE_NAME);
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
		tok.text = cstr_dup(varstr_view(buf));
		running = 0;
		break;
	case BUILD_ASSIGNMENT:
		// =
		tok = token_new(TOKEN_TYPE_ASSIGNMENT);
		ts->next_state = READ_NEXT;
		running = 0;
		break;
	case BUILD_STRING:
		/* "multi
			line
				string
					with escape /"/n"
		*/
		tok = token_new(TOKEN_TYPE_STRING);
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
			tok.text = cstr_dup(varstr_view(buf));
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
		tok = token_new(TOKEN_TYPE_NEWLINE);
		ts->next_state = READ_NEXT;
		running = 0;
		break;
	case BUILD_END:
		tok = token_new(TOKEN_TYPE_NEWLINE);
		ts->end = 1;
		running = 0;
		break;
	case ERROR:
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