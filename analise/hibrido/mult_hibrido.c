#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <mpi.h>
#include <omp.h>

int *cria_matriz(int N);
void inicia_matrix_file(int *matriz, int N, char *filename);
void free_matriz(int *matriz);
void write_matrix_file(int *matriz, int N, char *filename);

void multiply(int *A, int *B, int *C, int rows_per_proc, int N) {
    #pragma omp parallel for
    for (int i = 0; i < rows_per_proc; i++) {
        for (int k = 0; k < N; k++) {
            int val = A[i * N + k];
            for (int j = 0; j < N; j++) {
                C[i * N + j] += val * B[k * N + j];
            }
        }
    }
}

int main(int argc, char *argv[]) {
    int rank, size, N;
    int *A = NULL, *B = NULL, *C = NULL, *local_A, *local_C;
    int *sendcounts = NULL, *displs = NULL;
    char filename_A[50], filename_B[50], filename_C[50];

    //set threads max
    //omp_set_num_threads(omp_get_max_threads());

    // Tempo total de execução
    double tempo_total_inicio = MPI_Wtime();
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    if (argc < 2) {
        if (rank == 0) printf("Uso: mpirun -np <num_procs> %s <N>\n", argv[0]);
        MPI_Finalize();
        return 1;
    }

    N = atoi(argv[1]);

    // Tempo de comunicação (inicialização e broadcast)

    if (rank == 0) {
        A = cria_matriz(N);
        B = cria_matriz(N);
        C = (int *)calloc(N * N, sizeof(int));

        sprintf(filename_A, "matrix_A_%d.csv", N);
        sprintf(filename_B, "matrix_B_%d.csv", N);
        sprintf(filename_C, "matrix_C1_%d.csv", N);

        inicia_matrix_file(A, N, filename_A);
        inicia_matrix_file(B, N, filename_B);
    } else {
        B = cria_matriz(N);
    }

    double tempo_comunicacao = MPI_Wtime();
    MPI_Bcast(B, N * N, MPI_INT, 0, MPI_COMM_WORLD);
    tempo_comunicacao = MPI_Wtime() - tempo_comunicacao;

    // Definir a distribuição de linhas entre os processos
    int local_rows = (N / size) + (rank < N % size ? 1 : 0);

    if (rank == 0) {
        sendcounts = (int *)malloc(size * sizeof(int));
        displs = (int *)malloc(size * sizeof(int));
        int offset = 0;
        for (int i = 0; i < size; i++) {
            sendcounts[i] = ((N / size) + (i < N % size ? 1 : 0)) * N;
            displs[i] = offset;
            offset += sendcounts[i];
        }
    }

    local_A = (int *)malloc(local_rows * N * sizeof(int));
    local_C = (int *)calloc(local_rows * N, sizeof(int));

    if (!local_A || !local_C) {
        printf("Erro na alocação de memória no processo %d\n", rank);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    // Tempo de comunicação (MPI_Scatterv)
    double tempo_scatter = MPI_Wtime();
    MPI_Scatterv(A, sendcounts, displs, MPI_INT, local_A, local_rows * N, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Tempo de computação (multiplicação de matrizes)
    double tempo_computacao = MPI_Wtime();
    multiply(local_A, B, local_C, local_rows, N);
    tempo_computacao = MPI_Wtime() - tempo_computacao;

    // Tempo de comunicação (MPI_Gatherv)
    MPI_Gatherv(local_C, local_rows * N, MPI_INT, C, sendcounts, displs, MPI_INT, 0, MPI_COMM_WORLD);
    tempo_scatter = MPI_Wtime() - tempo_scatter;


    // Tempo total de execução
    double tempo_total_fim = MPI_Wtime() - tempo_total_inicio;

    // Processo 0 imprime os tempos e escreve a matriz final
    if (rank == 0) {
        write_matrix_file(C, N, filename_C);
        
       // printf("### Tempos de Execução Híbrido (MPI + OpenMP) ###\n");
        printf("Tempo total: %f segundos\n", tempo_total_fim);
        printf("Tempo de comunicação (Bcast + Scatterv): %f segundos\n", tempo_comunicacao );
        printf("Tempo de computação (Multiplicação): %f segundos\n", tempo_computacao);
        printf("Tempo de comunicação (Gatherv): %f segundos\n", tempo_scatter);
        
        free(A);
        free(C);
        free(sendcounts);
        free(displs);
    }

    free(B);
    free(local_A);
    free(local_C);

    MPI_Finalize();
    return 0;
}

// Criação de matriz dinâmica
int *cria_matriz(int N) {
    int *matriz = (int *)malloc(N * N * sizeof(int));
    if (!matriz) {
        printf("Erro na alocação de memória\n");
        exit(1);
    }
    return matriz;
}

// Função para ler ficheiros CSV
void inicia_matrix_file(int *matriz, int N, char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    size_t buffer_size = 0;
    char *linha = NULL;

    for (int i = 0; i < N; i++) {
        getline(&linha, &buffer_size, file);
        char *ptr = linha;
        for (int j = 0; j < N; j++) {
            matriz[i * N + j] = strtol(ptr, &ptr, 10);
            if (*ptr == ',') ptr++;
        }
    }

    free(linha);
    fclose(file);
}

// Função para escrever ficheiros CSV
void write_matrix_file(int *matriz, int N, char *filename) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        MPI_Abort(MPI_COMM_WORLD, 1);
    }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            fprintf(file, "%d", matriz[i * N + j]);
            if (j < N - 1) fprintf(file, ",");
        }
        fprintf(file, "\n");
    }

    fclose(file);
}

// Libertar memória
void free_matriz(int *matriz) {
    free(matriz);
}
