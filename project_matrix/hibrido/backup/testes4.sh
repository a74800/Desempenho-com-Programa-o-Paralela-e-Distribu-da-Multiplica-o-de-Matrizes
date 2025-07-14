#!/bin/bash

programa="./mult_hibrido"
python_script="gera_matrix.py"

configs=(
    "--host fct-deei-linux:2"
    "--host fct-deei-linux:3"
    "--host fct-deei-linux:4"
    "--host fct-deei-linux:4 --host fct-deei-aval:1"
    "--host fct-deei-linux:4 --host fct-deei-aval:2"
)

num_processos=(2 3 4 5 6)

for N in $(seq 4 5); do
    tamanho=$((2**N))
    output_file="tempos_${tamanho}.csv"

    python3 $python_script $tamanho
    echo "Execução,Configuração,np,OMP_Threads,Tempo_real,Tempo_user,Tempo_sys,Tempo_total,Tempo_Bcast_Scatterv,Tempo_Computacao,Tempo_Gatherv" > $output_file

    ### Parte 1 - Configurações padrão
    for i in "${!configs[@]}"; do
        config="${configs[$i]}"
        np="${num_processos[$i]}"
        export OMP_NUM_THREADS=2

        echo "Executando $np MPI + $OMP_NUM_THREADS OMP: $config"
        mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

        echo "Uptime antes da execução: $(uptime)" >> $output_file

        total_real=0; total_user=0; total_sys=0
        total_tempo_total=0; total_tempo_bcast_scatterv=0
        total_tempo_computacao=0; total_tempo_gatherv=0

        for j in $(seq 1 3); do
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "Matrizes diferentes para $config com tamanho $tamanho!"
                exit 1
            fi

            tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

            tempo_real=$(echo "$output" | grep "real" | awk '{print $2}' | awk -F'm' '{print ($1*60)+$2}')
            tempo_user=$(echo "$output" | grep "user" | awk '{print $2}' | awk -F'm' '{print ($1*60)+$2}')
            tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}' | awk -F'm' '{print ($1*60)+$2}')

            echo "$j,\"$config\",$np,$OMP_NUM_THREADS,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file

            total_real=$(awk "BEGIN {print $total_real + $tempo_real}")
            total_user=$(awk "BEGIN {print $total_user + $tempo_user}")
            total_sys=$(awk "BEGIN {print $total_sys + $tempo_sys}")
            total_tempo_total=$(awk "BEGIN {print $total_tempo_total + $tempo_total}")
            total_tempo_bcast_scatterv=$(awk "BEGIN {print $total_tempo_bcast_scatterv + $tempo_bcast_scatterv}")
            total_tempo_computacao=$(awk "BEGIN {print $total_tempo_computacao + $tempo_computacao}")
            total_tempo_gatherv=$(awk "BEGIN {print $total_tempo_gatherv + $tempo_gatherv}")
        done

        echo "Uptime depois da execução: $(uptime)" >> $output_file

        echo "Média,\"$config\",$np,$OMP_NUM_THREADS,$(
            awk "BEGIN {printf \"%.6f\", $total_real / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_user / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_sys / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_tempo_total / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_tempo_bcast_scatterv / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_tempo_computacao / 3}"),$(
            awk "BEGIN {printf \"%.6f\", $total_tempo_gatherv / 3}") >> $output_file
    done

done
done
    rm -f matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv


echo "Testes concluídos. Resultados em tempos_*.csv"

