#include "iniparser.h"
#include <assert.h>
#include <stdio.h>
int main(void)
{
	struct ini * ini = ini_new();
	assert(ini != NULL);
	
	FILE * fid = fopen("testfile", "r");
	assert(fid != NULL);
	int res = ini_read(ini, fid);
	fclose(fid);
	
	assert(res == 0);
	
	ini_set(ini, "aa", "pswd", "1234");
	ini_set(ini, "aa", "pswd", "1234");
	ini_write(ini, stdout);
	ini_del(ini);
	return 0;
}