import numpy as np
import pandas as pd
import sys

# Verificar se o argumento foi passado
if len(sys.argv) != 2:
    print("Uso correto: python script.py <N>")
    sys.exit(1)

# Obter N a partir dos argumentos da linha de comandos
N = int(sys.argv[1])

# Gerar matrizes A e B aleatórias de tamanho N x N
A = np.random.randint(0, 10, (N, N))
B = np.random.randint(0, 10, (N, N))

# Multiplicar as matrizes
C = np.dot(A, B)

# Guardar as matrizes em ficheiros CSV
pd.DataFrame(A).to_csv(f"matrix_A_{N}.csv", index=False, header=False)
pd.DataFrame(B).to_csv(f"matrix_B_{N}.csv", index=False, header=False)
pd.DataFrame(C).to_csv(f"matrix_C_{N}.csv", index=False, header=False)

