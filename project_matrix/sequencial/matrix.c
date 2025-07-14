#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<math.h>



// Criacao de matrizes
int **cria_matriz(int N) {
    int **matriz = (int **)malloc(N * sizeof(int *));
    for (int i = 0; i < N; i++) {
        matriz[i] = (int *)malloc(N *  sizeof(int));
    }
    return matriz;
}


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

    for (int i = 0; i < N; i++){
        for(int j = 0; j < N; j++) {
            matriz[i][j] = rand() % 100;
        }
    }
    
}

int main() {

    int N = 3250;

    while (N <= 3250)
    {
        int **matrix_A = cria_matriz(N);
        int **matrix_B = cria_matriz(N);

        inicia_matriz(matrix_A, N);
        inicia_matriz(matrix_B, N);

        char filename_A[50];
        char filename_B[50];

        sprintf(filename_A, "matrix_A_%d.csv", N);
        sprintf(filename_B, "matrix_B_%d.csv", N);

        //escrever para um ficheiro
        FILE *file_A = fopen(filename_A, "w");
        FILE *file_B = fopen(filename_B, "w");

        if (file_A == NULL || file_B == NULL)
        {
            printf("Erro ao abrir o ficheiro\n");
            return 1;
        }


        for (int i = 0; i < N; i++)
        {
            for (int j = 0; j < N; j++)
            {
                fprintf(file_A, "%d", matrix_A[i][j]);
                fprintf(file_B, "%d", matrix_B[i][j]);

                if (j < N - 1)
                {
                    fprintf(file_A, ",");
                    fprintf(file_B, ",");
                }
            }
            fprintf(file_A, "\n");
            fprintf(file_B, "\n");
        }

        fclose(file_A);
        fclose(file_B);

        N+=500;

        free(matrix_A);
        free(matrix_B);

        
    }
    
}