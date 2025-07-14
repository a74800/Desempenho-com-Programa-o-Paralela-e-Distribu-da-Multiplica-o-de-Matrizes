#!/bin/bash

# Nome do programa a executar
programa="./mult_mpi_time"
python_script="gera_matrix.py"

# Definição das configurações de distribuição de processos MPI e seus totais
configs=(
    "--host fct-deei-linux:2"                      # 2 processos (só no linux)
    "--host fct-deei-linux:3"                      # 3 processos (só no linux)
    "--host fct-deei-linux:4"                      # 4 processos (só no linux)
    "--host fct-deei-linux:4 --host fct-deei-aval:1"  # 5 processos (4 linux + 1 aval)
    "--host fct-deei-linux:4 --host fct-deei-aval:2"  # 6 processos (4 linux + 2 aval)
)

num_processos=(2 3 4 5 6)  # Número total de processos para cada configuração correspondente

# Loop externo para variar o tamanho da matriz como potências de 2 (2^N), de N=8 até N=10
for N in $(seq 2 5); do
    tamanho=$((2**N))  # Calcula 2^N

    # Nome do ficheiro onde os tempos serão guardados
    output_file="tempos_${tamanho}.csv"

    # Gera as matrizes iniciais
    #python3 $python_script $tamanho

    # Limpa ficheiro antes de iniciar
    echo "Execução,Configuração,np,Tempo_real,Tempo_user,Tempo_sys,Tempo_total,Tempo_Bcast_Scatterv,Tempo_Computacao,Tempo_Gatherv" > $output_file

    # Loop para cada configuração de distribuição de processos
    for i in "${!configs[@]}"; do
        config="${configs[$i]}"
        np="${num_processos[$i]}"

        echo "Executando com configuração: $config e np=$np"

	mpiexec -v $config -np $np $programa $tamanho > /dev/null 2 >&1

	# Captura o uptime antes das execuções
        echo "Uptime antes da execução: $(uptime)" >> $output_file

        # Inicializa a soma total dos tempos
        total_real=0
        total_user=0
        total_sys=0
        total_tempo_total=0
        total_tempo_bcast_scatterv=0
        total_tempo_computacao=0
        total_tempo_gatherv=0

        # Loop para executar 30 vezes
        for j in $(seq 1 30); do
            # Executa o programa e mede o tempo com `time`
            output=$( { time mpiexec -v $config -np $np $programa $tamanho; } 2>&1 )

            # Comparar as matrizes geradas pelo programa em C e pelo script Python
            if ! diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null; then
                echo "As matrizes são diferentes para tamanho $tamanho e configuração $config. Interrompendo a execução."
                exit 1
            fi

            # Capturar os tempos de execução MPI do output do programa
            tempo_total=$(echo "$output" | grep "Tempo total:" | head -n 1 | awk '{print $3}')
            tempo_bcast_scatterv=$(echo "$output" | grep "Tempo de comunicação (Bcast + Scatterv):" | awk '{print $7}')
            tempo_computacao=$(echo "$output" | grep "Tempo de computação (Multiplicação):" | awk '{print $5}')
            tempo_gatherv=$(echo "$output" | grep "Tempo de comunicação (Gatherv):" | awk '{print $5}')

            # Se alguma variável estiver vazia, definir como 0 para evitar erro no `awk`
            tempo_total=${tempo_total:-0}
            tempo_bcast_scatterv=${tempo_bcast_scatterv:-0}
            tempo_computacao=${tempo_computacao:-0}
            tempo_gatherv=${tempo_gatherv:-0}

            # Capturar os tempos do `time`
            tempo_real=$(echo "$output" | grep "real" | awk '{print $2}')
            tempo_user=$(echo "$output" | grep "user" | awk '{print $2}')
            tempo_sys=$(echo "$output" | grep "sys" | awk '{print $2}')

            # Converter tempos do formato mm:ss para segundos
            tempo_real=$(echo $tempo_real | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_user=$(echo $tempo_user | awk -F'm' '{print ($1 * 60) + $2}')
            tempo_sys=$(echo $tempo_sys | awk -F'm' '{print ($1 * 60) + $2}')

            # Guardar os valores no CSV
            echo "$j,\"$config\",$np,$tempo_real,$tempo_user,$tempo_sys,$tempo_total,$tempo_bcast_scatterv,$tempo_computacao,$tempo_gatherv" >> $output_file

            # Somar os tempos para calcular médias
            total_real=$(awk "BEGIN {print $total_real + $tempo_real}")
            total_user=$(awk "BEGIN {print $total_user + $tempo_user}")
            total_sys=$(awk "BEGIN {print $total_sys + $tempo_sys}")
            total_tempo_total=$(awk "BEGIN {print $total_tempo_total + $tempo_total}")
            total_tempo_bcast_scatterv=$(awk "BEGIN {print $total_tempo_bcast_scatterv + $tempo_bcast_scatterv}")
            total_tempo_computacao=$(awk "BEGIN {print $total_tempo_computacao + $tempo_computacao}")
            total_tempo_gatherv=$(awk "BEGIN {print $total_tempo_gatherv + $tempo_gatherv}")

            echo "Execução $j: Configuração=$config, np=$np, real=$tempo_real, user=$tempo_user, sys=$tempo_sys, total=$tempo_total, bcast_scatterv=$tempo_bcast_scatterv, computacao=$tempo_computacao, gatherv=$tempo_gatherv"
        done

	# Captura o uptime depois das execuções
        echo "Uptime depois da execução: $(uptime)" >> $output_file

        # Calcular médias
        media_real=$(awk "BEGIN {print $total_real / 30}")
        media_user=$(awk "BEGIN {print $total_user / 30}")
        media_sys=$(awk "BEGIN {print $total_sys / 30}")
        media_tempo_total=$(awk "BEGIN {print $total_tempo_total / 30}")
        media_tempo_bcast_scatterv=$(awk "BEGIN {print $total_tempo_bcast_scatterv / 30}")
        media_tempo_computacao=$(awk "BEGIN {print $total_tempo_computacao / 30}")
        media_tempo_gatherv=$(awk "BEGIN {print $total_tempo_gatherv / 30}")

        # Guardar as médias no CSV
        echo "Média,\"$config\",$np,$media_real,$media_user,$media_sys,$media_tempo_total,$media_tempo_bcast_scatterv,$media_tempo_computacao,$media_tempo_gatherv" >> $output_file
    done

    # Remover as matrizes geradas após as execuções
    rm -f matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv
done

echo "Testes concluídos! Resultados guardados nos ficheiros tempos_*.csv"

