import pandas as pd
import matplotlib.pyplot as plt
import os
import re

# Diretoria atual
current_dir = os.getcwd()

# Procurar todos os ficheiros tempos_*.csv
csv_files = [f for f in os.listdir(current_dir) if f.startswith("tempos_") and f.endswith(".csv")]
print("Ficheiros encontrados:")
for f in csv_files:
    print(f)

# Guardar métricas extraídas
metricas = []

for file in csv_files:
    print(f"\nA processar: {file}")
    match = re.search(r"tempos_(\d+)\.csv", file)
    if not match:
        print("  -> Nome de ficheiro ignorado (sem match)")
        continue
    matrix_size = int(match.group(1))

    try:
        with open(os.path.join(current_dir, file), 'r') as f:
            linhas = f.readlines()
            for linha in linhas:
                if linha.startswith("Média"):
                    partes = linha.strip().split(',')
                    tempo_real = float(partes[1])
                    print(f"  -> Tempo real médio (linha 'Média'): {tempo_real:.7f} s")
                    metricas.append({"MatrixSize": matrix_size, "Tempo Médio (s)": tempo_real})
                    break
            else:
                print("  -> Linha 'Média' não encontrada.")
    except Exception as e:
        print(f"  -> Erro ao processar ficheiro: {e}")

if not metricas:
    print("Nenhum tempo médio válido encontrado. Verifica os ficheiros CSV.")
    exit(1)

# Criar DataFrame final
metricas_execucao = pd.DataFrame(metricas).sort_values(by="MatrixSize")

# Guardar CSV com as métricas
metricas_execucao.to_csv("metricas_execucao.csv", index=False)

# Gerar gráfico
plt.figure(figsize=(10, 6))
plt.plot(metricas_execucao["MatrixSize"], metricas_execucao["Tempo Médio (s)"], '-o')
plt.title("Tempo Médio de Execução (Real) por Tamanho de Matriz (Sequencial)")
plt.xlabel("Tamanho da Matriz")
plt.ylabel("Tempo Médio (s)")
plt.grid(True)
plt.xticks(metricas_execucao["MatrixSize"])
plt.tight_layout()

# Guardar gráfico
plt.savefig("tempo_execucao_sequencial.png")
print("\nMétricas e gráfico gerados com sucesso!")
