Performance Study — Matrix Multiplication with Parallel and Distributed Programming

This repository contains the source code, test scripts, and final report for a case study developed as part of the Parallel and Distributed Systems course in the Computer Engineering degree at the University of Algarve.
 Objective

Evaluate the performance of different approaches to square matrix multiplication by comparing:

    Sequential implementation (C)

    Parallel implementation with OpenMP

    Distributed implementation with MPI

    Hybrid implementation with MPI + OpenMP

 Technologies and Tools

    C programming language

    GCC compiler with OpenMP and MPI support

    MPI (Open MPI)

    OpenMP

    SLURM (for HPC job scheduling — Cirrus)

    Python (for data analysis and graph generation)

    Bash (for automated test execution)

 Evaluation Metrics

    Execution time

    Speedup

    Efficiency

    Communication time (MPI and hybrid versions)

    Scalability (strong and weak scaling)

 Report

The full technical report, including results, graphs, test environments, and conclusions, is available at relatorio_SPD_caso_de_estudo_Matrizes.pdf.

 Key Findings

    OpenMP was effective for medium and large workloads, achieving speedups up to 3.6×.

    MPI provided modest gains, highly dependent on workload size per process.

    The hybrid version showed promising results but required fine-tuning.

    Scalability was limited on local machines, but better performance is expected on HPC platforms.
