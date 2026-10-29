#!/bin/bash
#SBATCH --job-name=hap_HG002
#SBATCH --partition=compute
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --output=logs/slurm/hap_%j.out
#SBATCH --error=logs/slurm/hap_%j.err

set -euo pipefail

SAMPLE="${1:?Provide sample ID}"
BASE="/home/rao.faheem/wgs_benchmark_bqsr/snakemake_dv"
CONTAINER="/lustre/rao.faheem/wgs_benchmark/containers/hap.py_0.3.14.sif"
TRUTH="/lustre/rao.faheem/wgs_benchmark/data/benchmark/HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz"
BED="/lustre/rao.faheem/wgs_benchmark/data/benchmark/HG002_GRCh38_1_22_v4.2.1_benchmark_noinconsistent.bed"
REF="/lustre/rao.faheem/wgs_benchmark/data/reference/Homo_sapiens_assembly38.fasta"
VCF="${BASE}/results/deepvariant/${SAMPLE}.bwa_mem2.deepvariant.vcf.gz"
PREFIX="${BASE}/results/benchmark/${SAMPLE}.bwa_mem2"

mkdir -p "$(dirname "$PREFIX")"

singularity exec \
  --bind /lustre:/lustre \
  --bind /home/rao.faheem/wgs_benchmark_bqsr:/home_bqsr \
  "$CONTAINER" \
  hap.py "$TRUTH" "$VCF" \
  -f "$BED" \
  -r "$REF" \
  -o "/home_bqsr/snakemake_dv/results/benchmark/${SAMPLE}.bwa_mem2" \
  --engine=vcfeval \
  --threads=4
