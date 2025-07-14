# makefile para exercicios da aula de revisão SPDis

CC = gcc
CFLAGS = -Wall -std=gnu99
LDFLAGS = -lm


SRC2 = mult_matrix.c
SRC3 = matrix.c
SRC4 = mult_mpi2.c
SRC5 = mult_mpi_time.c


EXECS = mult_matrix matrix mult_mpi mult_mpi_time


all: mult_matrix matrix mult_mpi mult_mpi_time
.PHONY: all 

mult_matrix: $(SRC2) makefile
	$(CC) $(CFLAGS) $(SRC2) $(LDFLAGS) -o $@

matrix: $(SRC3) makefile
	$(CC) $(CFLAGS) $(SRC3) $(LDFLAGS) -o $@

mult_mpi: $(SRC4) makefile
	mpicc $(CFLAGS) $(SRC4) $(LDFLAGS) -o $@

mult_mpi_time: $(SRC5) makefile
	mpicc $(CFLAGS) $(SRC5) $(LDFLAGS) -o $@

clean:
	rm -f $(EXECS)
