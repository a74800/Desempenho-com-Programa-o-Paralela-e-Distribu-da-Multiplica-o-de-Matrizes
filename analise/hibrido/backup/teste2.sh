#!/bin/bash

# Nome do programa a executar
programa="./mult_hibrido"
python_script="gera_matrix.py"

# Configurações de distribuição de processos MPI originais (semelhante ao MPI puro)
configs=(
    "--host fct-deei-linux:2"
    "--host fct-deei-linux:3"
    "--host fct-deei-linux:4"
    "--host fct-deei-linux:4 --host fct-deei-aval:1"
    "--host fct-deei-linux:4 --host fct-deei-aval:2"
)

num_processos=(2 3 4 5 6)

# Loop externo para variar o tamanho da matriz (2^N)
for N in $(seq 4 4); do
    tamanho=$((2**N))
    output_file="tempos_${tamanho}.csv"

    python3 $python_script $tamanho

    echo "Execução,MPI_Config,np,OMP_Threads,Tempo_real,Tempo_user,Tempo_sys,Tempo_total,Tempo_Bcast_Scatterv,Tempo_Computacao,Tempo_Gatherv" > $output_file

    ### Parte 1 - Configurações idênticas ao MPI puro, mas com OMP_NUM_THREADS fixo
    for i in "${!configs[@]}"; do
        config="${configs[$i]}"
        np="${num_processos[$i]}"
        export OMP_NUM_THREADS=2  # Podes ajustar aqui se quiseres testar outras combinações

        echo "Executando com configuração MPI: $config (np=$np), OpenMP: $OMP_NUM_THREADS threads"

        # Primeira execução para "aquecimento"
        mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

        for j in $(seq 1 30); do
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "As matrizes são diferentes para tamanho $tamanho e configuração $config. Interrompendo a execução."
                exit 1
            fi

            tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

            tempo_total=${tempo_total:-0}
            tempo_bcast_scatterv=${tempo_bcast_scatterv:-0}
            tempo_computacao=${tempo_computacao:-0}
            tempo_gatherv=${tempo_gatherv:-0}

            tempo_real=$(echo "$output" | grep "real" | awk '{print $2}')
            tempo_user=$(echo "$output" | grep "user" | awk '{print $2}')
            tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}')

            tempo_real=$(echo $tempo_real | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_user=$(echo $tempo_user | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_sys=$(echo $tempo_sys | awk -F'm' '{print ($1 * 60) + $2}')

            echo "$j,\"$config\",$np,$OMP_NUM_THREADS,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file
        done
    done

    echo "SEGUNDA PARTE - Configurações híbridas específicas com diferentes OMP_NUM_THREADS" >> $output_file


    ### Parte 2 - Novas configurações híbridas específicas com diferentes OMP_NUM_THREADS
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

        echo "Executando com MPI: $config (np=$np), OpenMP: $omp threads"

        mpiexec -v $config -np $np $programa $tamanho > /dev/null 2>&1

        for j in $(seq 1 3); do
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "As matrizes são diferentes para tamanho $tamanho e configuração $config. Interrompendo a execução."
                exit 1
            fi

            tempo_total=$(echo "$output" | grep "Tempo total:" | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

            tempo_total=${tempo_total:-0}
            tempo_bcast_scatterv=${tempo_bcast_scatterv:-0}
            tempo_computacao=${tempo_computacao:-0}
            tempo_gatherv=${tempo_gatherv:-0}

            tempo_real=$(echo "$output" | grep "real" | awk '{print $2}')
            tempo_user=$(echo "$output" | grep "user" | awk '{print $2}')
            tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}')

            tempo_real=$(echo $tempo_real | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_user=$(echo $tempo_user | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_sys=$(echo $tempo_sys | awk -F'm' '{print ($1 * 60) + $2}')

            echo "$j,\"$config\",$np,$omp,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file
        done
    done

    # Remover matrizes temporárias
    rm -f matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv
done

echo "Testes concluídos! Resultados guardados nos ficheiros tempos_*.csv"

