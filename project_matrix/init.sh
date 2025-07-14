#!/bin/bash

# Gerar todas as matrizes necessárias
python_script="gera_matrix.py"

# Gerar todas as matrizes
for N in $(seq 8 11); do
    tamanho=$((2**N))  # Calcula 2^N
    python3 $python_script $tamanho
done

# Lista das pastas onde as matrizes serão copiadas
folders=("sequencial" "openmp" "mpi" "hibrido")

# Copiar as matrizes para cada pasta e executar testes.sh dentro da respetiva pasta
for folder in "${folders[@]}"; do
    # Verifica se a pasta existe
    if [ ! -d "$folder" ]; then
        echo "Erro: A pasta $folder não existe!"
        continue  # Passa para a próxima pasta sem tentar copiar/executar
    fi

    # Copiar as matrizes
    cp matrix_* "$folder/"
    echo "Matrizes copiadas para a pasta $folder"

    # Verifica se testes.sh existe dentro da pasta antes de tentar executar
    if [ -f "$folder/testes.sh" ]; then
        (cd "$folder" && bash testes.sh &> log.txt)
        echo "Testes executados em $folder, log guardado em $folder/log.txt"
    else
        echo "Erro: testes.sh não encontrado em $folder!"
    fi
done

# Remover as matrizes geradas na pasta principal
rm -f matrix_*
echo "Matrizes removidas"
