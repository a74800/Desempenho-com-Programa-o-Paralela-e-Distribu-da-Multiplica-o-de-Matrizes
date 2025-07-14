#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <omp.h>

int *cria_matriz(int N);
void inicia_matrix_file(int *matriz, int N, char *filename);
void free_matriz(int *matriz);
void write_matrix_file(int *matriz, int N, char *filename);

int main(int argc, char const *argv[])
{
    clock_t start, end;
    double cpu_time_used;

    struct timespec inicio, fim;
    
    if (argc < 2)
    {
        printf("Uso: %s <N>\n", argv[0]);
        return 1;
    }

    int N = atoi(argv[1]);

    // Alocar memória para as matrizes
    int *A = cria_matriz(N);
    int *B = cria_matriz(N);
    int *C = (int *)calloc(N * N, sizeof(int)); // Inicializa com 0

    if (!A || !B || !C)
    {
        printf("Erro na alocação de memória\n");
        exit(1);
    }

    char filename_A[50], filename_B[50], filename_C[50];

    sprintf(filename_A, "matrix_A_%d.csv", N);
    sprintf(filename_B, "matrix_B_%d.csv", N);
    sprintf(filename_C, "matrix_C1_%d.csv", N);

    // Ler as matrizes dos ficheiros CSV
    inicia_matrix_file(A, N, filename_A);
    inicia_matrix_file(B, N, filename_B);


    clock_gettime(CLOCK_MONOTONIC, &inicio);



    // Multiplicação de matrizes paralelizada
    #pragma omp parallel for collapse(2) shared(A, B, C, N)
    for (int i = 0; i < N; i++)
    {
        for (int k = 0; k < N; k++)
        {
            for (int j = 0; j < N; j++)
            {
                C[i * N + j] += A[i * N + k] * B[k * N + j];
            }
        }
    }
    

    clock_gettime(CLOCK_MONOTONIC, &fim);

    // Guardar a matriz C no ficheiro CSV
    write_matrix_file(C, N, filename_C);

    // Libertar memória
    free_matriz(A);
    free_matriz(B);
    free_matriz(C);

    double percorrido = (fim.tv_sec - inicio.tv_sec) + (fim.tv_nsec - inicio.tv_nsec) / 1e9;
    printf("Time = %f seconds\n", percorrido);
    return 0;
}

// Função para criar matriz dinamicamente
int *cria_matriz(int N)
{
    int *matriz = (int *)malloc(N * N * sizeof(int));
    if (!matriz)
    {
        printf("Erro na alocação de memória\n");
        exit(1);
    }
    return matriz;
}

// Função para ler matrizes de ficheiros CSV
void inicia_matrix_file(int *matriz, int N, char *filename)
{
    FILE *file = fopen(filename, "r");
    if (file == NULL)
    {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        exit(1);
    }

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            fscanf(file, "%d,", &matriz[i * N + j]);
        }
    }

    fclose(file);
}

// Função para escrever a matriz no ficheiro CSV
void write_matrix_file(int *matriz, int N, char *filename)
{
    FILE *file = fopen(filename, "w");
    if (file == NULL)
    {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        exit(1);
    }

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            fprintf(file, "%d", matriz[i * N + j]);
            if (j < N - 1) fprintf(file, ",");
        }
        fprintf(file, "\n");
    }

    fclose(file);
}

// Função para libertar memória
void free_matriz(int *matriz)
{
    free(matriz);
}
