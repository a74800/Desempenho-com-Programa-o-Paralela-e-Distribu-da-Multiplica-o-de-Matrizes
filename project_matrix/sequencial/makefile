# makefile para exercicios da aula de revisão SPDis

CC = gcc
CFLAGS = -Wall -std=gnu99
LDFLAGS = -lm


SRC2 = mult_matrix.c
SRC3 = matrix.c


EXECS = mult_matrix matrix


all: mult_matrix matrix
.PHONY: all 

mult_matrix: $(SRC2) makefile
	$(CC) $(CFLAGS) $(SRC2) $(LDFLAGS) -o $@

matrix: $(SRC3) makefile
	$(CC) $(CFLAGS) $(SRC3) $(LDFLAGS) -o $@

clean:
	rm -f $(EXECS)