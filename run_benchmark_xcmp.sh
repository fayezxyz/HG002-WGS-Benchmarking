#!/bin/bash
#SBATCH --job-name=hap_xcmp
#SBATCH --partition=compute
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --output=logs/slurm/xcmp_%j.out
#SBATCH --error=logs/slurm/xcmp_%j.err

set -euo pipefail

SAMPLE="${1:?Provide sample ID}"
BASE="/home/rao.faheem/wgs_benchmark_bqsr/snakemake_dv"
CONTAINER="/lustre/rao.faheem/wgs_benchmark/containers/hap.py_0.3.14.sif"

mkdir -p "$BASE/logs/slurm" "$BASE/results/benchmark"

singularity exec \
  --bind /lustre:/lustre \
  --bind /home/rao.faheem/wgs_benchmark_bqsr:/home_bqsr \
  "$CONTAINER" \
  hap.py \
  /lustre/rao.faheem/wgs_benchmark/data/benchmark/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz \
  "/home_bqsr/snakemake_dv/results/deepvariant/${SAMPLE}.bwa_mem2.deepvariant.vcf.gz" \
  -f /lustre/rao.faheem/wgs_benchmark/data/benchmark/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed \
  -r /lustre/rao.faheem/wgs_benchmark/data/reference/Homo_sapiens_assembly38.fasta \
  -o "/home_bqsr/snakemake_dv/results/benchmark/${SAMPLE}.bwa_mem2" \
  --engine=xcmp \
  --threads=4
