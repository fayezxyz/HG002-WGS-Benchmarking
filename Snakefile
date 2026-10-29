configfile: "config.yaml"

SAMPLES = config["samples"]
ROOT = config["project_root"]
WORK = "/home/rao.faheem/wgs_benchmark_bqsr"
OUT = f"{WORK}/snakemake_dv/results"

rule all:
    input:
        expand(
            "results/benchmark/{sample}.bwa_mem2.summary.csv",
            sample=SAMPLES
        )

rule deepvariant:
    input:
        bam=lambda wc: config["bams"][wc.sample],
        bai=lambda wc: config["bams"][wc.sample].replace(".bam", ".bai"),
        reference=config["reference"],
        container=config["deepvariant_container"]
    output:
        vcf=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.vcf.gz",
        vcf_tbi=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.vcf.gz.tbi",
        gvcf=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.g.vcf.gz",
        gvcf_tbi=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.g.vcf.gz.tbi"
    log:
        "logs/deepvariant/{sample}.log"
    threads: 8
    resources:
        mem_mb=64000,
        runtime=1440
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname {output.vcf})" "$(dirname {log})"

        singularity exec \
          --bind /lustre/rao.faheem/wgs_benchmark:/work \
          --bind /home/rao.faheem/wgs_benchmark_bqsr:/home_bqsr \
          {input.container:q} \
          /opt/deepvariant/bin/run_deepvariant \
          --model_type=WGS \
          --ref=/work/data/reference/Homo_sapiens_assembly38.fasta \
          --reads=/home_bqsr/results/{wildcards.sample}.bwa_mem2/{wildcards.sample}.bwa_mem2.bqsr.bam \
          --output_vcf=/home_bqsr/snakemake_dv/results/deepvariant/{wildcards.sample}.bwa_mem2.deepvariant.vcf.gz \
          --output_gvcf=/home_bqsr/snakemake_dv/results/deepvariant/{wildcards.sample}.bwa_mem2.deepvariant.g.vcf.gz \
          --num_shards={threads} \
          > {log:q} 2>&1

        test -s {output.vcf:q}
        test -s {output.vcf_tbi:q}
        test -s {output.gvcf:q}
        test -s {output.gvcf_tbi:q}
        """

rule benchmark:
    input:
        vcf=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.vcf.gz",
        vcf_tbi=f"{OUT}/deepvariant/{{sample}}.bwa_mem2.deepvariant.vcf.gz.tbi",
        truth=config["truth_vcf"],
        bed=config["evaluation_bed"],
        reference=config["reference"],
        container=config["hap_container"]
    output:
        summary="results/benchmark/{sample}.bwa_mem2.summary.csv"
    log:
        "logs/benchmark/{sample}.log"
    threads: config["benchmark_threads"]
    resources:
        mem_mb=16000,
        runtime=360
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname {output.summary})" "$(dirname {log})"

        singularity exec \
          --bind /lustre:/lustre \
          --bind /home/rao.faheem/wgs_benchmark_bqsr:/home_bqsr \
          {input.container:q} \
          hap.py \
          {input.truth:q} \
          {input.vcf:q} \
          -f {input.bed:q} \
          -r {input.reference:q} \
          -o /home_bqsr/snakemake_dv/results/benchmark/{wildcards.sample}.bwa_mem2 \
          --engine=vcfeval \
          --threads={threads} \
          > {log:q} 2>&1

        test -s {output.summary:q}
        """
