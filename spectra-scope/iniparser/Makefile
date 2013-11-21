CC:=gcc
#compile and link flags
ifeq ($(OS), Windows_NT)
	RM = del
	BIN = a.exe
	LDFLAGS += -lMingw32
else
	RM = rm
	BIN = a.out
endif

LDFLAGS+=-lm
CFLAGS+=-std=c99\
	-pedantic-errors -Wstrict-aliasing=0 -Wall\
	-g\

#file names and directories
DIR=.
SRC=$(wildcard $(DIR:%=%/*.c))
OBJ=$(SRC:.c=.o)
DEP=$(SRC:.c=.d)

#rules
$(BIN): $(OBJ)
	$(CC) $^ $(LDFLAGS) -o $(BIN)
-include $(DEP)
%.o: %.c
	$(CC) $< $(CFLAGS) -c -o $@ -MMD -MP 

run: $(BIN)
	$(BIN)
clean:
	$(RM) $(OBJ) $(DEP) $(BIN)
.PHONY: all run pack clean
