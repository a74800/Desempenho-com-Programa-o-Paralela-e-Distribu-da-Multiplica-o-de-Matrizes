# Matrix Multiplication Performance Study — Parallel and Distributed Programming

This repository contains source code, test scripts, performance analysis, and a final report developed for the **Parallel and Distributed Systems** course at the **University of Algarve**.

## Objective

The goal of this project is to **evaluate and compare the performance** of square matrix multiplication using different programming models:
- Sequential Implementation (C)
- Parallel Implementation with OpenMP
- Distributed Implementation with MPI
- Hybrid Implementation combining MPI + OpenMP

## Technologies & Tools

| Tool            | Purpose                               |
|-----------------|----------------------------------------|
| C Language      | Core matrix multiplication code       |
| GCC             | Compilation with OpenMP and MPI       |
| OpenMP          | Parallelization on shared memory      |
| MPI (Open MPI)  | Distributed memory parallelization    |
| Python          | Data analysis and graph generation    |
| SLURM           | HPC job scheduling (Cirrus cluster)   |
| Bash            | Automation of test runs               |


## Evaluation Metrics

- Execution Time
- Speedup
- Efficiency
- Communication Time (MPI/Hybrid)
- Scalability — Strong and Weak Scaling

## Final Report

For full methodology, results, and conclusions, see the final report:

[`relatorio_SPD_caso_de_estudo_Matrizes.pdf`](relatorio_SPD_caso_de_estudo_Matrizes.pdf)

## Key Findings

- OpenMP achieved up to 3.6× speedup on larger workloads.
- MPI showed modest speedup, limited by communication overhead.
- Hybrid (MPI + OpenMP) provided promising results but required careful tuning.
- Scalability improved on HPC environments compared to local machines.