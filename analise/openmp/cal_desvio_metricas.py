import pandas as pd
import matplotlib.pyplot as plt
import os
import re

# Diretoria atual
current_dir = os.getcwd()

# Criar diretoria para os gráficos, se não existir
graficos_dir = os.path.join(current_dir, "graficos_openmp")
os.makedirs(graficos_dir, exist_ok=True)

# Procurar ficheiros tempos_*.csv com threads (OpenMP)
csv_files = [f for f in os.listdir(current_dir) if f.startswith("tempos_") and "threads" in f and f.endswith(".csv")]

# Lista para guardar resultados
resultados = []

for file in csv_files:
    match = re.search(r"tempos_(\d+)_threads(\d+)\.csv", file)
    if not match:
        continue
    matrix_size = int(match.group(1))
    threads = int(match.group(2))

    # Ler ficheiro ignorando as primeiras duas linhas e as últimas
    df = pd.read_csv(os.path.join(current_dir, file), skiprows=2, nrows=30, names=["Execucao", "Tempo_real", "Tempo_user", "Tempo_sys", "Tempo_extra"])

    desvio_real = df["Tempo_real"].std()
    desvio_extra = df["Tempo_extra"].std()
    media_real = df["Tempo_real"].mean()

    # Procurar o ficheiro sequencial correspondente
    ficheiro_seq = f"tempos_{matrix_size}.csv"
    if not os.path.exists(os.path.join(current_dir, ficheiro_seq)):
        print(f"Aviso: ficheiro sequencial '{ficheiro_seq}' não encontrado. Ignorado para speedup/eficiência.")
        tempo_seq = None
        speedup = None
        eficiencia = None
    else:
        # Ler média do tempo_real da linha que começa por 'Média'
        with open(os.path.join(current_dir, ficheiro_seq), 'r') as fseq:
            linhas_seq = fseq.readlines()
            for linha in linhas_seq:
                if linha.startswith("Média"):
                    partes_seq = linha.strip().split(',')
                    tempo_seq = float(partes_seq[1])
                    speedup = tempo_seq / media_real
                    eficiencia = (speedup / threads) * 100
                    break
            else:
                tempo_seq = None
                speedup = None
                eficiencia = None

    resultados.append({
        "Ficheiro": file,
        "MatrixSize": matrix_size,
        "Threads": threads,
        "Desvio_Padrao_Real": desvio_real,
        "Desvio_Padrao_Extra": desvio_extra,
        "Tempo_Medio_Real": media_real,
        "Tempo_Sequencial": tempo_seq,
        "Speedup": speedup,
        "Eficiência (%)": eficiencia
    })

# Criar DataFrame final
df_resultados = pd.DataFrame(resultados).sort_values(by=["MatrixSize", "Threads"])

# Guardar para CSV
df_resultados.to_csv("metricas_openmp.csv", index=False)
print("Métricas (desvios, tempo, speedup, eficiência) guardadas com sucesso em 'metricas_openmp.csv'")

# Gerar gráficos por métrica
metricas_para_grafico = [
    ("Tempo_Medio_Real", "Tempo Médio (s)"),
    ("Desvio_Padrao_Real", "Desvio Padrão Tempo Real"),
    ("Desvio_Padrao_Extra", "Desvio Padrão Tempo Extra"),
    ("Speedup", "Speedup"),
    ("Eficiência (%)", "Eficiência (%)")
]

for metrica, titulo in metricas_para_grafico:
    plt.figure(figsize=(10, 6))
    for matrix_size in sorted(df_resultados["MatrixSize"].unique()):
        subset = df_resultados[df_resultados["MatrixSize"] == matrix_size]
        plt.plot(subset["Threads"], subset[metrica], '-o', label=f"{matrix_size}x{matrix_size}")

    plt.title(f"{titulo} por Nº de Threads")
    plt.xlabel("Nº de Threads")
    plt.ylabel(titulo)
    plt.grid(True, linestyle='--', linewidth=0.5)
    plt.legend(title="Tamanho da Matriz")
    plt.tight_layout()
    nome_ficheiro = f"grafico_{metrica.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('%', 'percent')}.png"
    plt.savefig(os.path.join(graficos_dir, nome_ficheiro))

print("Gráficos gerados com sucesso na pasta 'graficos_openmp'!")
