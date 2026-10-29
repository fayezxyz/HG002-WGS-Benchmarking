#!/bin/bash
#SBATCH --job-name=DV_HG002
#SBATCH --partition=compute
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=24:00:00
#SBATCH --output=logs/slurm/DV_%j.out
#SBATCH --error=logs/slurm/DV_%j.err

set -euo pipefail

SAMPLE="${1:?Provide sample ID}"

BAM="/home/rao.faheem/wgs_benchmark_bqsr/results/${SAMPLE}.bwa_mem2/${SAMPLE}.bwa_mem2.bqsr.bam"
REF="/lustre/rao.faheem/wgs_benchmark/data/reference/Homo_sapiens_assembly38.fasta"
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
  --output_vcf="${OUT}/${SAMPLE}.bwa_mem2.deepvariant.vcf.gz" \
  --output_gvcf="${OUT}/${SAMPLE}.bwa_mem2.deepvariant.g.vcf.gz" \
  --num_shards=8
