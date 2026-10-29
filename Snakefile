SAMPLES = config["samples"]
BAMS = config["bams"]
REFERENCE = config["reference"]
DV_CONTAINER = config["deepvariant_container"]
HAP_CONTAINER = config["hap_container"]
TRUTH_VCF = config["truth_vcf"]
EVALUATION_BED = config["evaluation_bed"]
BENCHMARK_THREADS = config.get("benchmark_threads", 4)

# Optional: directory containing pre-existing DeepVariant VCFs.
# If not specified, VCFs are expected under results/deepvariant/.
DV_RESULTS = config.get("deepvariant_results", "results/deepvariant")

rule all:
    input:
        expand(
            "results/benchmark/{sample}.bwa_mem2.summary.csv",
            sample=SAMPLES
        )

rule deepvariant:
    input:
        bam=lambda wc: BAMS[wc.sample],
        bai=lambda wc: BAMS[wc.sample] + ".bai",
        reference=REFERENCE,
        container=DV_CONTAINER
    output:
        vcf=f"{DV_RESULTS}/{{sample}}.bwa_mem2.deepvariant.vcf.gz",
        vcf_tbi=f"{DV_RESULTS}/{{sample}}.bwa_mem2.deepvariant.vcf.gz.tbi",
        gvcf=f"{DV_RESULTS}/{{sample}}.bwa_mem2.deepvariant.g.vcf.gz",
        gvcf_tbi=f"{DV_RESULTS}/{{sample}}.bwa_mem2.deepvariant.g.vcf.gz.tbi"
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
          --bind "$(dirname {input.reference})":"$(dirname {input.reference})" \
          --bind "$(dirname {input.bam})":"$(dirname {input.bam})" \
          {input.container:q} \
          /opt/deepvariant/bin/run_deepvariant \
          --model_type=WGS \
          --ref={input.reference:q} \
          --reads={input.bam:q} \
          --output_vcf={output.vcf:q} \
          --output_gvcf={output.gvcf:q} \
          --num_shards={threads} \
          > {log:q} 2>&1

        test -s {output.vcf:q}
        test -s {output.vcf_tbi:q}
        test -s {output.gvcf:q}
        test -s {output.gvcf_tbi:q}
        """

rule benchmark:
    input:
        vcf=lambda wc: f"{DV_RESULTS}/{wc.sample}.bwa_mem2.deepvariant.vcf.gz",
        vcf_tbi=lambda wc: f"{DV_RESULTS}/{wc.sample}.bwa_mem2.deepvariant.vcf.gz.tbi",
        truth=TRUTH_VCF,
        bed=EVALUATION_BED,
        reference=REFERENCE,
        container=HAP_CONTAINER
    output:
        summary="results/benchmark/{sample}.bwa_mem2.summary.csv"
    log:
        "logs/benchmark/{sample}.log"
    threads: BENCHMARK_THREADS
    resources:
        mem_mb=16000,
        runtime=360
    shell:
        r"""
        set -euo pipefail
        mkdir -p "$(dirname {output.summary})" "$(dirname {log})"

        singularity exec \
          --bind "$(dirname {input.reference})":"$(dirname {input.reference})" \
          --bind "$(dirname {input.truth})":"$(dirname {input.truth})" \
          --bind "$(dirname {input.vcf})":"$(dirname {input.vcf})" \
          --bind "$(dirname {input.bed})":"$(dirname {input.bed})" \
          {input.container:q} \
          hap.py \
          {input.truth:q} \
          {input.vcf:q} \
          -f {input.bed:q} \
          -r {input.reference:q} \
          -o results/benchmark/{wildcards.sample}.bwa_mem2 \
          --engine=vcfeval \
          --threads={threads} \
          > {log:q} 2>&1

        test -s {output.summary:q}
        """
