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

for N in $(seq 4 4); do
    tamanho=$((2**N))
    output_file="tempos_${tamanho}.csv"

    python3 $python_script $tamanho
    echo "Execução,MPI_Config,np,OMP_Threads,Tempo_real,Tempo_user,Tempo_sys,Tempo_total,Tempo_Bcast_Scatterv,Tempo_Computacao,Tempo_Gatherv" > $output_file

    ## PARTE 1 - Configurações com OMP fixo
    for i in "${!configs[@]}"; do
        config="${configs[$i]}"
        np="${num_processos[$i]}"
        export OMP_NUM_THREADS=2

        echo "Executando com MPI: $config (np=$np), OpenMP: $OMP_NUM_THREADS threads"
        mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

        total_real=0; total_user=0; total_sys=0
        total_tempo_total=0; total_tempo_bcast_scatterv=0
        total_tempo_computacao=0; total_tempo_gatherv=0

        for j in $(seq 1 5); do
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "Matrizes diferentes em $tamanho com $config"
                exit 1
            fi

            tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

            tempo_real=$(echo "$output" | grep "real" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_user=$(echo "$output" | grep "user" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}' | awk -F'm' '{print ($1 * 60) + $2}')

            echo "$j,\"$config\",$np,$OMP_NUM_THREADS,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file

            total_real=$(awk "BEGIN {print $total_real + $tempo_real}")
            total_user=$(awk "BEGIN {print $total_user + $tempo_user}")
            total_sys=$(awk "BEGIN {print $total_sys + $tempo_sys}")
            total_tempo_total=$(awk "BEGIN {print $total_tempo_total + $tempo_total}")
            total_tempo_bcast_scatterv=$(awk "BEGIN {print $total_tempo_bcast_scatterv + $tempo_bcast_scatterv}")
            total_tempo_computacao=$(awk "BEGIN {print $total_tempo_computacao + $tempo_computacao}")
            total_tempo_gatherv=$(awk "BEGIN {print $total_tempo_gatherv + $tempo_gatherv}")
        done

        echo "Média,\"$config\",$np,$OMP_NUM_THREADS,$(
            awk "BEGIN {print $total_real/5}"),$(
            awk "BEGIN {print $total_user/5}"),$(
            awk "BEGIN {print $total_sys/5}"),$(
            awk "BEGIN {print $total_tempo_total/5}"),$(
            awk "BEGIN {print $total_tempo_bcast_scatterv/5}"),$(
            awk "BEGIN {print $total_tempo_computacao/5}"),$(
            awk "BEGIN {print $total_tempo_gatherv/5}") >> $output_file
    done

    echo "segunda parte" >> $output_file

    ## PARTE 2 - Novas configs híbridas
    novas_configs=(
        "--host fct-deei-linux:1"
        "--host fct-deei-linux:2"
        "--host fct-deei-linux:4"
        "--host fct-deei-linux:1 --host fct-deei-aval:1"
        "--host fct-deei-linux:2 --host fct-deei-aval:1"
    )
    omp_threads=(4 2 1 4 2)

    for i in "${!novas_configs[@]}"; do
        config="${novas_configs[$i]}"
        np=$(echo "$config" | grep -o '[0-9]' | awk '{s+=$1} END {print s}')
        omp="${omp_threads[$i]}"
        export OMP_NUM_THREADS=$omp

        echo "Executando com MPI: $config np=$np, OpenMP: $omp threads"
        mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

        total_real=0; total_user=0; total_sys=0
        total_tempo_total=0; total_tempo_bcast_scatterv=0
        total_tempo_computacao=0; total_tempo_gatherv=0

        for j in $(seq 1 5); do
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "Matrizes diferentes em $tamanho com $config"
                exit 1
            fi

            tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

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

        echo "Média,\"$config\",$np,$omp,$(
            awk "BEGIN {print $total_real/5}"),$(
            awk "BEGIN {print $total_user/5}"),$(
            awk "BEGIN {print $total_sys/5}"),$(
            awk "BEGIN {print $total_tempo_total/5}"),$(
            awk "BEGIN {print $total_tempo_bcast_scatterv/5}"),$(
            awk "BEGIN {print $total_tempo_computacao/5}"),$(
            awk "BEGIN {print $total_tempo_gatherv/5}") >> $output_file
    done

    rm -f matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv
done

echo "Testes concluídos! Resultados guardados nos ficheiros tempos_*.csv"

