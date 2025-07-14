#include<stdio.h>
#include<stdlib.h>
#include<string.h>


int **cria_matriz(int N);
void inicia_matriz(int **matriz, int N);
void inicia_matrix_file(int **matriz, int N, char *file);
void inicia_matriz_zeros(int **matriz, int N);
void print_matriz(int **matriz, int N);
void free_matriz(int **matriz, int N);
void write_matrix_file(int **matriz, int N, char *filename);


int main(int argc, char const *argv[])
{
    // Recebe o tamanho da matriz
    int N = atoi(argv[1]);
    //int N = 2;


    // Alocar memória para as matrizes
    int **A = cria_matriz(N);
    int **B = cria_matriz(N);
    int **C = cria_matriz(N);

    char filename_A[20];
    char filename_B[20];


    //char *filename_A = "matrix_A_2.csv";
    sprintf(filename_A, "matrix_A_%d.csv", N);
    sprintf(filename_B, "matrix_B_%d.csv", N);

    // Iniciar matrizes
    inicia_matrix_file(A, N, filename_A);
    inicia_matrix_file(B, N, filename_B);
    /*  */
    /* print_matriz(A, N);
    printf("\n");
    print_matriz(B, N); */
    inicia_matriz_zeros(C, N);

    
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            for (int k = 0; k < N; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }   
        }     
    }

    char filename_C[20];
    sprintf(filename_C, "matrix_C1_%d.csv", N);

    write_matrix_file(C, N, filename_C);

//    print_matriz(C, N);



    // Liberar memória
    free_matriz(A, N);
    free_matriz(B, N);
    free_matriz(C, N);



    return 0;
}



/*********funcoes auxiliares**********/

int **cria_matriz(int N) {
    int **matriz = (int **)malloc(N * sizeof(int *));
    int *data = (int *)malloc(N * N * sizeof(int)); // Bloco único

    if (!matriz || !data) {
        printf("Erro na alocação de memória\n");
        exit(1);
    }

    for (int i = 0; i < N; i++) {
        matriz[i] = &data[i * N]; // Cada linha aponta para uma secção do array
    }

    return matriz;
}

/* 
// Criacao de matrizes
int **cria_matriz(int N) {
    int **matriz = (int **)malloc(N * sizeof(int *));
    for (int i = 0; i < N; i++) {
        matriz[i] = (int *)malloc(N *  sizeof(int));
    }
    return matriz;
}
 */
//iniciar tudo com zeros
void inicia_matriz_zeros(int **matriz, int N) {
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++){
            matriz[i][j] = 0;
        }
    }
}

// Iniciar matrizes random
void inicia_matriz(int **matriz , int N) {
    /* for (int i = 0; i < N; i++){
        for(int j = 0; j < N; j++) {
            matriz[i][j] = rand() % 10;
        }
    } */
    memset(matriz[0], 0, N * N * sizeof(int));

    
}

void inicia_matrix_file(int **matriz, int N, char *filename) {
    FILE *file = fopen(filename, "r");
    if (file == NULL) {
        printf("Erro ao abrir o ficheiro %s\n", filename);
        exit(1);
    }

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            if (j == N - 1) {
                fscanf(file, "%d", &matriz[i][j]); // Último número (sem vírgula)
            } else {
                fscanf(file, "%d,", &matriz[i][j]); // Números seguidos de vírgula
            }
        }
    }

    fclose(file);
}


void print_matriz(int **matriz, int N) {
    for (int i = 0; i < N; i++){
        for(int j = 0; j < N; j++) {
            printf("%d ", matriz[i][j]);
        }
        printf("\n");
        /* code */
    }
    
}

void free_matriz(int **matriz, int N) {
    /* for (int i = 0; i < N; i++) {
        free(matriz[i]);
    } */
    free(matriz[0]);
    free(matriz);
}

void write_matrix_file(int **matriz, int N, char *filename) {
    FILE *file = fopen(filename, "w");

    if (file == NULL) {
        printf("Erro ao abrir o ficheiro\n");
        exit(1);
    }
    
    for (int i = 0; i < N; i++) {
        for (int j = 0; j < N; j++) {
            fprintf(file, "%d", matriz[i][j]);


            if (j < N - 1) {
                fprintf(file, ",");
            }

        }
        fprintf(file, "\n");
    }
    
    fclose(file);
    
}
