#!/bin/bash
#SBATCH --job-name=DV_chr20
#SBATCH --partition=compute
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=04:00:00
#SBATCH --output=logs/slurm/DV_chr20_%j.out
#SBATCH --error=logs/slurm/DV_chr20_%j.err

set -euo pipefail

SAMPLE="${1:?Provide sample ID}"
CONTAINER="/lustre/rao.faheem/wgs_benchmark/containers/deepvariant_latest.sif"
OUT="/home/rao.faheem/wgs_benchmark_bqsr/snakemake_dv/results/deepvariant"

mkdir -p "$OUT"

singularity exec \
  --bind /lustre/rao.faheem/wgs_benchmark:/work \
  --bind /home/rao.faheem/wgs_benchmark_bqsr:/home_bqsr \
  "$CONTAINER" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=WGS \
  --ref=/work/data/reference/Homo_sapiens_assembly38.fasta \
  --reads="/home_bqsr/results/${SAMPLE}.bwa_mem2/${SAMPLE}.bwa_mem2.bqsr.bam" \
  --regions=chr20 \
  --output_vcf="${OUT}/${SAMPLE}.bwa_mem2.chr20.vcf.gz" \
  --output_gvcf="${OUT}/${SAMPLE}.bwa_mem2.chr20.g.vcf.gz" \
  --num_shards=8
