#!/bin/bash

programa="./mult_hibrido"
python_script="gera_matrix.py"

# Configurações MPI
configs=(
    "--host fct-deei-linux:2"
    "--host fct-deei-linux:3"
    "--host fct-deei-linux:4"
    "--host fct-deei-linux:4 --host fct-deei-aval:1"
    "--host fct-deei-linux:4 --host fct-deei-aval:2"
)

num_processos=(2 3 4 5 6)

# OpenMP threads a testar
omp_threads=(2 4 6 8)

# Tamanhos de matriz (2^N)
for N in $(seq 8 11); do
    tamanho=$((2**N))
    output_file="tempos_hibrido_${tamanho}.csv"

    # Gerar matrizes
    python3 $python_script $tamanho

    # Cabeçalho CSV
    echo "Execução,MPI_Config,np,OMP_Threads,Tempo_real,Tempo_user,Tempo_sys,Tempo_total,Tempo_Bcast_Scatterv,Tempo_Computacao,Tempo_Gatherv" > $output_file

    # Para cada configuração MPI
    for i in "${!configs[@]}"; do
        config="${configs[$i]}"
        np="${num_processos[$i]}"

        # Para cada número de threads OpenMP
        for omp in "${omp_threads[@]}"; do
            export OMP_NUM_THREADS=$omp

            echo "Executando: MPI np=$np, OMP=$omp threads, matriz ${tamanho}x${tamanho}"
            mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

            echo "Uptime antes da execução: $(uptime)" >> $output_file

            # Inicializar somatórios
            total_real=0; total_user=0; total_sys=0
            total_tempo_total=0; total_tempo_bcast_scatterv=0
            total_tempo_computacao=0; total_tempo_gatherv=0

            for j in $(seq 1 30); do
                output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

                if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                    echo "Erro: Matrizes diferentes em tamanho $tamanho, MPI np=$np, OMP=$omp"
                    exit 1
                fi

                tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
                tempo_bcast_scatterv=$(echo "$output" | grep "Bcast" | awk '{print $7}')
                tempo_computacao=$(echo "$output" | grep "Multiplicação" | awk '{print $5}')
                tempo_gatherv=$(echo "$output" | grep "Gatherv" | awk '{print $5}')

                tempo_real=$(echo "$output" | grep "real" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')
                tempo_user=$(echo "$output" | grep "user" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')
                tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')

                echo "$j,\"$config\",$np,$omp,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file

                total_real=$(awk "BEGIN {print $total_real + $tempo_real}")
                total_user=$(awk "BEGIN {print $total_user + $tempo_user}")
                total_sys=$(awk "BEGIN {print $total_sys + $tempo_sys}")
                total_tempo_total=$(awk "BEGIN {print $total_tempo_total + $tempo_total}")
                total_tempo_bcast_scatterv=$(awk "BEGIN {print $total_tempo_bcast_scatterv + $tempo_bcast_scatterv}")
                total_tempo_computacao=$(awk "BEGIN {print $total_tempo_computacao + $tempo_computacao}")
                total_tempo_gatherv=$(awk "BEGIN {print $total_tempo_gatherv + $tempo_gatherv}")
            done

            echo "Uptime depois da execução: $(uptime)" >> $output_file

            # Calcular médias
            media_real=$(awk "BEGIN {printf \"%.6f\", $total_real / 30}")
            media_user=$(awk "BEGIN {printf \"%.6f\", $total_user / 30}")
            media_sys=$(awk "BEGIN {printf \"%.6f\", $total_sys / 30}")
            media_tempo_total=$(awk "BEGIN {printf \"%.6f\", $total_tempo_total / 30}")
            media_tempo_bcast_scatterv=$(awk "BEGIN {printf \"%.6f\", $total_tempo_bcast_scatterv / 30}")
            media_tempo_computacao=$(awk "BEGIN {printf \"%.6f\", $total_tempo_computacao / 30}")
            media_tempo_gatherv=$(awk "BEGIN {printf \"%.6f\", $total_tempo_gatherv / 30}")

            # Escrever média no CSV
            echo "Média,\"$config\",$np,$omp,$media_real,$media_user,$media_sys,$media_tempo_total,$media_tempo_bcast_scatterv,$media_tempo_computacao,$media_tempo_gatherv" >> $output_file
        done
    done

    # Limpar matrizes
    rm -f matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv
done

echo "✅ Testes concluídos. Resultados guardados em tempos_hibrido_*.csv"

