#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mpi/mpi.h>

int *cria_matriz(int N);
void inicia_matrix_file(int *matriz, int N, char *filename);
void inicia_matriz_zeros(int *matriz, int N);
void free_matriz(int *matriz);
void write_matrix_file(int *matriz, int N, char *filename);

int main(int argc, char *argv[])
{
    int rank, size, N;
    int *A, *B, *C, *local_A, *local_C;
    int *sendcounts, *displs;
    int *recvcounts, *recvdispls;
    char filename_A[20], filename_B[20], filename_C[20];
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;

    MPI_Init(&argc, &argv);                 // Inicializa o ambiente MPI
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);   // Obtém o rank do processo
    MPI_Comm_size(MPI_COMM_WORLD, &size);   // Obtém o número total de processos
    MPI_Get_processor_name(processor_name, &name_len); // Obtém o nome da máquina

    // Cada processo imprime a sua mensagem de saudação
    printf("Olá do processo %d de %d! Estou a correr em %s.\n", rank, size, processor_name);
    MPI_Barrier(MPI_COMM_WORLD); // Sincroniza para garantir que as mensagens aparecem ordenadas

    if (argc < 2)
    {
        if (rank == 0)
        {
            printf("Uso: mpirun -np <num_procs> %s <N>\n", argv[0]);
        }
        MPI_Finalize();
        return 1;
    }

    N = atoi(argv[1]);

    if (rank == 0)
    {
        // Processo 0 carrega as matrizes A e B dos ficheiros
        A = cria_matriz(N);
        B = cria_matriz(N);
        C = cria_matriz(N);

        sprintf(filename_A, "matrix_A_%d.csv", N);
        sprintf(filename_B, "matrix_B_%d.csv", N);

        inicia_matrix_file(A, N, filename_A);
        inicia_matrix_file(B, N, filename_B);
    }
    else
    {
        B = cria_matriz(N); // Todos os processos precisam de B
    }

    // Distribuir a matriz B para todos os processos
    MPI_Bcast(B, N * N, MPI_INT, 0, MPI_COMM_WORLD);

    // Criar os arrays de distribuição para MPI_Scatterv
    int local_rows;
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

    local_rows = (N / size) + (rank < N % size ? 1 : 0);

    // Cria submatrizes locais para cada processo
    local_A = (int *)malloc(local_rows * N * sizeof(int));
    local_C = (int *)malloc(local_rows * N * sizeof(int));

    if (!local_A || !local_C)
    {
        printf("Erro na alocação de memória do processo %d\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    // Envia as linhas da matriz A para cada processo
    MPI_Scatterv(A, sendcounts, displs, MPI_INT,
                 local_A, local_rows * N, MPI_INT,
                 0, MPI_COMM_WORLD);

    printf("Processo %d em %s: Recebeu %d linhas e está a iniciar a multiplicação.\n", rank, processor_name, local_rows);

    // Multiplicação de matrizes local
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

    // Criar os arrays de distribuição para MPI_Gatherv
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

    // Recolher os resultados no processo 0
    MPI_Gatherv(local_C, local_rows * N, MPI_INT,
                C, recvcounts, recvdispls, MPI_INT,
                0, MPI_COMM_WORLD);

    if (rank == 0)
    {
        sprintf(filename_C, "matrix_C1_%d.csv", N);
        write_matrix_file(C, N, filename_C);
        free_matriz(A);
        free_matriz(C);
        free(sendcounts);
        free(displs);
        free(recvcounts);
        free(recvdispls);
    }

    free_matriz(B);
    free(local_A);
    free(local_C);

    MPI_Finalize();
    return 0;
}


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
            if (j == N - 1)
            {
                fscanf(file, "%d", &matriz[i * N + j]);
            }
            else
            {
                fscanf(file, "%d,", &matriz[i * N + j]);
            }
        }
    }

    fclose(file);
}

void free_matriz(int *matriz)
{
    free(matriz);
}

void write_matrix_file(int *matriz, int N, char *filename)
{
    FILE *file = fopen(filename, "w");

    if (file == NULL)
    {
        printf("Erro ao abrir o ficheiro\n");
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    for (int i = 0; i < N; i++)
    {
        for (int j = 0; j < N; j++)
        {
            fprintf(file, "%d", matriz[i * N + j]);
            if (j < N - 1)
                fprintf(file, ",");
        }
        fprintf(file, "\n");
    }

    fclose(file);
}

