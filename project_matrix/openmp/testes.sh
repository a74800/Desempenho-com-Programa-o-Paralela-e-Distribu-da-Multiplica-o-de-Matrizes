#!/bin/bash

# Nome do programa a executar
programa="./mult_openmp"  # Altera para o nome correto do teu executável
python_script="gera_matrix.py"

# gerar todas a matrizes
#for N in $(seq 8 11); do
 #   tamanho=$((2**N))  # Calcula 2^N
  #  python3 $python_script $tamanho
#done

#make clean
#make mult_openmp

# Loop para variar o número de threads OpenMP (de 1 a 4)
for threads in {2..10..2}; do

    # Loop externo para variar o tamanho da matriz como potências de 2 (2^N), de N=8 até N=12
    for N in $(seq 8 11); do
        tamanho=$((2**N))  # Calcula 2^N

        # Nome do ficheiro onde os tempos serão guardados
        output_file="tempos_${tamanho}_threads${threads}.csv"

        #python $python_script $tamanho

        # Inicializa a soma total dos tempos
        total_real=0
        total_user=0
        total_sys=0
        total_extra=0  # Novo para somar os tempos extras

        # Limpa ficheiro antes de iniciar
        echo "Execução,Tempo_real,Tempo_user,Tempo_sys,Tempo_extra" > $output_file

	# Captura o uptime antes das execuções
        echo "Uptime antes da execução: $(uptime)" >> $output_file

        # Executa uma vez (ignorar esta execução)
        export OMP_NUM_THREADS=$threads
        $programa $tamanho > /dev/null 2>&1

        # Loop para executar 30 vezes (ignora a primeira)
        for i in $(seq 1 30); do
            # Executa o programa e mede o tempo com `time`
            tempos=$( { time OMP_NUM_THREADS=$threads $programa $tamanho; } 2>&1 )

            # Extrai o tempo de execução impresso pelo programa
            tempo_extra=$(echo "$tempos" | grep "Time =" | awk '{print $3}')

            # Comparar as matrizes geradas
            diff matrix_C1_${tamanho}.csv matrix_C_${tamanho}.csv > /dev/null
            if [ $? -ne 0 ]; then
                echo "As matrizes são diferentes para tamanho $tamanho e threads=$threads. Interrompendo a execução."
                exit 1
            fi

            # Extrai os tempos corretos do comando `time`
            tempo_real=$(echo "$tempos" | grep "real" | awk '{print $2}')
            tempo_user=$(echo "$tempos" | grep "user" | awk '{print $2}')
            tempo_sys=$(echo "$tempos" | grep "sys" | awk '{print $2}')

            # Converte o tempo para segundos (formato mm:ss para segundos)
            tempo_real=$(echo $tempo_real | awk -F'm' '{print ($1 * 60) + $2}' )
            tempo_user=$(echo $tempo_user | awk -F'm' '{print ($1 * 60) + $2}' )
            tempo_sys=$(echo $tempo_sys | awk -F'm' '{print ($1 * 60) + $2}' )

            echo "$i,$tempo_real,$tempo_user,$tempo_sys,$tempo_extra" >> $output_file

            # Soma aos totais usando `awk`
            total_real=$(awk "BEGIN {print $total_real + $tempo_real}")
            total_user=$(awk "BEGIN {print $total_user + $tempo_user}")
            total_sys=$(awk "BEGIN {print $total_sys + $tempo_sys}")
            total_extra=$(awk "BEGIN {print $total_extra + $tempo_extra}")

            echo "Execução $i: threads=$threads, real $tempo_real, user $tempo_user, sys $tempo_sys, extra $tempo_extra"
        done

        #rm matrix_A_${tamanho}.csv matrix_B_${tamanho}.csv matrix_C_${tamanho}.csv matrix_C1_${tamanho}.csv


        # Calcular médias
        media_real=$(awk "BEGIN {print $total_real / 30}")
        media_user=$(awk "BEGIN {print $total_user / 30}")
        media_sys=$(awk "BEGIN {print $total_sys / 30}")
        media_extra=$(awk "BEGIN {print $total_extra / 30}")

        echo "Média,$media_real,$media_user,$media_sys,$media_extra" >> $output_file
        echo "Total,$total_real,$total_user,$total_sys,$total_extra" >> $output_file

	# Captura o uptime depois das execuções
        echo "Uptime depois da execução: $(uptime)" >> $output_file
    done 

done

#remover todas a matrizes geradaspara os testes
rm matrix_A_*.csv matrix_B_*.csv matrix_C_*.csv matrix_C1_*.csv

echo "Testes concluídos! Resultados guardados nos ficheiros tempos_*.csv"
echo "Última média do tempo de execução: real=$media_real, user=$media_user, sys=$media_sys, extra=$media_extra"
