#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi/mpi.h>

int *cria_matriz(int N);
void inicia_matrix_file(int *matriz, int N, char *filename);
void write_matrix_file(int *matriz, int N, char *filename);
void multiply_matrices(int *local_A, int *B, int *local_C, int local_rows, int N);

int main(int argc, char *argv[])
{

    int rank, size, N;
    int *A = NULL, *B = NULL, *C = NULL, *local_A, *local_C;
    int *sendcounts = NULL, *displs = NULL, *recvcounts = NULL, *recvdispls = NULL;
    char filename_A[50], filename_B[50], filename_C[50];

    double tempo_inicio = MPI_Wtime();
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 2)
    {
        if (rank == 0) printf("Uso: mpirun -np <num_procs> %s <N>\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    N = atoi(argv[1]);
/*     double tempo_comunicacao = MPI_Wtime();
 */
    if (rank == 0)
    {
        A = cria_matriz(N);
        B = cria_matriz(N);
        C = (int *)calloc(N * N, sizeof(int));

        sprintf(filename_A, "matrix_A_%d.csv", N);
        sprintf(filename_B, "matrix_B_%d.csv", N);
        sprintf(filename_C, "matrix_C1_%d.csv", N);

        inicia_matrix_file(A, N, filename_A);
        inicia_matrix_file(B, N, filename_B);
    }
    else
    {
        B = cria_matriz(N);
        
    }

    double tempo_comunicacao = MPI_Wtime();

    MPI_Bcast(B, N * N, MPI_INT, 0, MPI_COMM_WORLD);

    tempo_comunicacao = MPI_Wtime() - tempo_comunicacao;

    
    int local_rows = (N / size) + (rank < N % size ? 1 : 0);

    if (rank == 0)
    {
        sendcounts = (int *)malloc(size * sizeof(int));
        displs = (int *)malloc(size * sizeof(int));
        int base_rows = N / size;
        int extra_rows = N % size;
        int offset = 0;

        for (int i = 0; i < size; i++)
        {
            sendcounts[i] = (base_rows + (i < extra_rows ? 1 : 0)) * N;
            displs[i] = offset;
            offset += sendcounts[i];
        }
    }

    local_A = (int *)malloc(local_rows * N * sizeof(int));
    local_C = (int *)calloc(local_rows * N, sizeof(int));

    double tempo_gather = MPI_Wtime();


    MPI_Scatterv(A, sendcounts, displs, MPI_INT, local_A, local_rows * N, MPI_INT, 0, MPI_COMM_WORLD);
    
    //tempo_comunicacao = MPI_Wtime() - tempo_comunicacao;

    double tempo_computacao = MPI_Wtime();
    multiply_matrices(local_A, B, local_C, local_rows, N);
    tempo_computacao = MPI_Wtime() - tempo_computacao;
    printf("Rank %d: Tempo de computação: %f segundos\n", rank, tempo_computacao);

    //double tempo_gather = MPI_Wtime();

    if (rank == 0)
    {
        recvcounts = (int *)malloc(size * sizeof(int));
        recvdispls = (int *)malloc(size * sizeof(int));
        int deslocamento = 0;

        for (int i = 0; i < size; i++)
        {
            recvcounts[i] = sendcounts[i];
            recvdispls[i] = deslocamento;
            deslocamento += recvcounts[i];
        }
    }

    MPI_Gatherv(local_C, local_rows * N, MPI_INT, C, recvcounts, recvdispls, MPI_INT, 0, MPI_COMM_WORLD);
    tempo_gather = MPI_Wtime() - tempo_gather;

    if (rank == 0)
    {
        write_matrix_file(C, N, filename_C);
        printf("Tempo total: %f segundos\n", MPI_Wtime() - tempo_inicio);
        printf("Tempo de comunicação (Bcast + Scatterv): %f segundos\n", tempo_comunicacao);
        printf("Tempo de computação (Multiplicação): %f segundos\n", tempo_computacao);
        printf("Tempo de comunicação (Gatherv): %f segundos\n", tempo_gather);

        free(A);
        free(C);
        free(sendcounts);
        free(displs);
        free(recvcounts);
        free(recvdispls);
        printf("Rank %d: Tempo total: %f segundos\n", rank, MPI_Wtime() - tempo_inicio);

    }

    free(B);
    free(local_A);
    free(local_C);


    MPI_Finalize();
    return 0;
}

/********* Funções auxiliares **********/

// Criação de matriz dinâmica
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

// Função otimizada para ler ficheiros CSV
void inicia_matrix_file(int *matriz, int N, char *filename)
{
    FILE *file = fopen(filename, "r");
    if (file == NULL)
    {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    size_t buffer_size = 0;
    char *linha = NULL;

    for (int i = 0; i < N; i++)
    {
        ssize_t linha_len = getline(&linha, &buffer_size, file);
        if (linha_len == -1)
        {
            printf("Erro ao ler linha do ficheiro %s\n", filename);
            free(linha);
            MPI_Abort(MPI_COMM_WORLD, 1);
        }

        char *ptr = linha;
        for (int j = 0; j < N; j++)
        {
            matriz[i * N + j] = strtol(ptr, &ptr, 10);
            if (*ptr == ',') ptr++; 
        }
    }

    free(linha);
    fclose(file);
}

// Função para escrever ficheiros CSV
void write_matrix_file(int *matriz, int N, char *filename)
{
    FILE *file = fopen(filename, "w");
    if (file == NULL)
    {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        MPI_Abort(MPI_COMM_WORLD, 1);
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

// Função de multiplicação de matrizes
void multiply_matrices(int *local_A, int *B, int *local_C, int local_rows, int N)
{
    for (int i = 0; i < local_rows; i++)
    {
        for (int k = 0; k < N; k++)
        {
            for (int j = 0; j < N; j++)
            {
                local_C[i * N + j] += local_A[i * N + k] * B[k * N + j];
            }
        }
    }
}

