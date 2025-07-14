import pandas as pd
import matplotlib.pyplot as plt
import os
import re

# Diretoria atual
current_dir = os.getcwd()

# Procurar todos os ficheiros tempos_*.csv com padrão de OpenMP
csv_files = [f for f in os.listdir(current_dir) if f.startswith("tempos_") and "threads" in f and f.endswith(".csv")]
print("Ficheiros encontrados:")
for f in csv_files:
    print(f)

# Guardar métricas extraídas
metricas = []

for file in csv_files:
    print(f"\nA processar: {file}")
    match = re.search(r"tempos_(\d+)_threads(\d+)\.csv", file)
    if not match:
        print("  -> Nome de ficheiro ignorado (sem match)")
        continue
    matrix_size = int(match.group(1))
    threads = int(match.group(2))

    try:
        with open(os.path.join(current_dir, file), 'r') as f:
            linhas = f.readlines()
            for linha in linhas:
                if linha.startswith("Média"):
                    partes = linha.strip().split(',')
                    tempo_real = float(partes[1])
                    print(f"  -> Tempo real médio (linha 'Média'): {tempo_real:.7f} s")
                    metricas.append({
                        "MatrixSize": matrix_size,
                        "Threads": threads,
                        "Tempo Médio (s)": tempo_real
                    })
                    break
            else:
                print("  -> Linha 'Média' não encontrada.")
    except Exception as e:
        print(f"  -> Erro ao processar ficheiro: {e}")

if not metricas:
    print("Nenhum tempo médio válido encontrado. Verifica os ficheiros CSV.")
    exit(1)

# Criar DataFrame final
metricas_execucao = pd.DataFrame(metricas).sort_values(by=["MatrixSize", "Threads"])

# Guardar CSV com as métricas
metricas_execucao.to_csv("metricas_execucao_openmp.csv", index=False)

# Calcular speedup e eficiência
speedup_df = metricas_execucao.copy()
speedup_df["T1"] = speedup_df.groupby("MatrixSize")["Tempo Médio (s)"].transform(lambda x: x.iloc[0])
speedup_df["Speedup"] = speedup_df["T1"] / speedup_df["Tempo Médio (s)"]
speedup_df["Eficiência (%)"] = (speedup_df["Speedup"] / speedup_df["Threads"]) * 100
speedup_df.to_csv("metricas_speedup_openmp.csv", index=False)

# Gráfico de tempo de execução
plt.figure(figsize=(10, 6))
for matrix_size in metricas_execucao["MatrixSize"].unique():
    subset = metricas_execucao[metricas_execucao["MatrixSize"] == matrix_size]
    plt.plot(subset["Threads"], subset["Tempo Médio (s)"], '-o', label=f"{matrix_size}x{matrix_size}")
plt.title("Tempo Médio de Execução (OpenMP) por Nº de Threads")
plt.xlabel("Nº de Threads")
plt.ylabel("Tempo Médio (s)")
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.legend(title="Tamanho da Matriz")
plt.xticks(metricas_execucao["Threads"].unique())
plt.ylim(bottom=metricas_execucao["Tempo Médio (s)"].min() * 0.95)
plt.tight_layout()
plt.savefig("tempo_execucao_openmp.png")

# Gráfico de speedup com linha ideal
plt.figure(figsize=(10, 6))
for matrix_size in speedup_df["MatrixSize"].unique():
    subset = speedup_df[speedup_df["MatrixSize"] == matrix_size]
    plt.plot(subset["Threads"], subset["Speedup"], '-o', label=f"{matrix_size}x{matrix_size}")

# Adicionar linha ideal (speedup linear)
max_threads = speedup_df["Threads"].max()
ideal_x = list(range(1, max_threads + 1))
ideal_y = ideal_x
plt.plot(ideal_x, ideal_y, 'k--', label="Speedup Ideal")

plt.title("Speedup (OpenMP) por Nº de Threads")
plt.xlabel("Nº de Threads")
plt.ylabel("Speedup")
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.legend(title="Tamanho da Matriz")
plt.xticks(speedup_df["Threads"].unique())
plt.tight_layout()
plt.savefig("speedup_openmp.png")

# Gráfico de eficiência
plt.figure(figsize=(10, 6))
for matrix_size in speedup_df["MatrixSize"].unique():
    subset = speedup_df[speedup_df["MatrixSize"] == matrix_size]
    plt.plot(subset["Threads"], subset["Eficiência (%)"], '-o', label=f"{matrix_size}x{matrix_size}")
plt.title("Eficiência (OpenMP) por Nº de Threads")
plt.xlabel("Nº de Threads")
plt.ylabel("Eficiência (%)")
plt.grid(True, which='both', linestyle='--', linewidth=0.5)
plt.legend(title="Tamanho da Matriz")
plt.xticks(speedup_df["Threads"].unique())
plt.tight_layout()
plt.savefig("eficiencia_openmp.png")

print("\nMétricas, gráficos de tempo, speedup (com linha ideal) e eficiência gerados com sucesso!")
