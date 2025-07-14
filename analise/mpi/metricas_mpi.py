import pandas as pd
import os
import re
from io import StringIO
import matplotlib.pyplot as plt

# Criar diretoria para gráficos
pasta_graficos = "graficos_mpi"
os.makedirs(pasta_graficos, exist_ok=True)

# Inicializar lista para todos os resultados
todos_resultados = []

# Obter todos os ficheiros MPI
ficheiros_mpi = [f for f in os.listdir() if f.startswith("mpi_tempos_") and f.endswith(".csv")]

for arquivo in ficheiros_mpi:
    match = re.search(r"mpi_tempos_(\d+)\.csv", arquivo)
    if not match:
        continue

    tamanho_matriz = match.group(1)
    ficheiro_seq = f"tempos_{tamanho_matriz}.csv"

    # Obter tempo médio sequencial
    tempo_sequencial = None
    if os.path.exists(ficheiro_seq):
        with open(ficheiro_seq, 'r') as fseq:
            for linha in fseq:
                if linha.startswith("Média"):
                    partes_seq = linha.strip().split(',')
                    tempo_sequencial = float(partes_seq[1])
                    break
    else:
        print(f"Ficheiro sequencial '{ficheiro_seq}' não encontrado!")
        continue

    with open(arquivo, "r") as f:
        linhas = f.readlines()

    indices_media = [i for i, linha in enumerate(linhas) if linha.startswith("Média")]
    indices_fim = indices_media[1:] + [len(linhas)]

    colunas = [c.strip() for c in linhas[0].strip().split(",")]

    for i, idx_inicio in enumerate(indices_media):
        idx_fim = indices_fim[i]
        bloco = linhas[idx_inicio - 30:idx_fim]

        df = pd.read_csv(StringIO("".join(bloco)), names=colunas, skiprows=1)

        if df.shape[0] < 30:
            continue

        df["Tempo_Comunicacao"] = df["Tempo_Gatherv"] - df["Tempo_Computacao"]

        tempo_real_std = df["Tempo_real"].std()
        tempo_total_std = df["Tempo_total"].std()
        tempo_computacao_std = df["Tempo_Computacao"].std()
        tempo_comunicacao_std = df["Tempo_Comunicacao"].std()

        tempo_medio_real = df["Tempo_real"].mean()
        tempo_medio_total = df["Tempo_total"].mean()
        tempo_medio_computacao = df["Tempo_Computacao"].mean()
        tempo_medio_comunicacao = df["Tempo_Comunicacao"].mean()

        np_val = int(df["np"].iloc[0])
        configuracao = df["Configuração"].iloc[0]

        speedup = tempo_sequencial / tempo_medio_total if tempo_sequencial else None
        eficiencia = (speedup / np_val) * 100 if speedup else None

        todos_resultados.append({
            "Matriz": int(tamanho_matriz),
            "np": np_val,
            "Configuração": configuracao,
            "Tempo_Medio_Real": tempo_medio_real,
            "Desvio_Real": tempo_real_std,
            "Tempo_Medio_Total": tempo_medio_total,
            "Desvio_Total": tempo_total_std,
            "Tempo_Medio_Computacao": tempo_medio_computacao,
            "Desvio_Computacao": tempo_computacao_std,
            "Tempo_Medio_Comunicacao": tempo_medio_comunicacao,
            "Desvio_Comunicacao": tempo_comunicacao_std,
            "Tempo_Sequencial": tempo_sequencial,
            "Speedup": speedup,
            "Eficiência (%)": eficiencia
        })

# Criar DataFrame final e guardar
resultado_df = pd.DataFrame(todos_resultados)
resultado_df.sort_values(by=["Matriz", "np"], inplace=True)
resultado_df.to_csv("metricas_mpi_completas.csv", index=False)
print("Métricas MPI completas guardadas em 'metricas_mpi_completas.csv'")

# Gerar gráficos
metricas = [
    ("Tempo_Medio_Total", "Tempo Médio Total (s)"),
    ("Tempo_Medio_Comunicacao", "Tempo Médio de Comunicação (s)"),
    ("Speedup", "Speedup"),
    ("Eficiência (%)", "Eficiência (%)")
]

for metrica, titulo in metricas:
    plt.figure(figsize=(10, 6))
    for matriz in sorted(resultado_df["Matriz"].unique()):
        subset = resultado_df[resultado_df["Matriz"] == matriz]
        plt.plot(subset["np"], subset[metrica], marker='o', label=f"{matriz}x{matriz}")

    plt.title(f"{titulo} por Nº de Processos")
    plt.xlabel("Nº de Processos")
    plt.ylabel(titulo)
    plt.grid(True, linestyle='--', linewidth=0.5)
    plt.legend(title="Tamanho da Matriz")
    plt.tight_layout()
    nome_ficheiro = f"grafico_{metrica.lower().replace(' ', '_').replace('(', '').replace(')', '').replace('%', 'percent')}.png"
    plt.savefig(os.path.join(pasta_graficos, nome_ficheiro))

print("Gráficos gerados com sucesso na pasta 'graficos_mpi'!")