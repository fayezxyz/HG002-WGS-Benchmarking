# HG002 Whole-Genome Sequencing (WGS) Benchmarking

A Snakemake-based workflow for benchmarking DeepVariant variant calls against the HG002 benchmark truth set using hap.py and Singularity.

## Project overview

This repository contains workflow code and helper scripts for evaluating whole-genome sequencing (WGS) variant calls. It is configured for three samples:

- `SRR37356337`
- `SRR37356338`
- `SRR37356339`

The workflow uses existing BQSR BAM files and DeepVariant VCF outputs, together with a reference genome and HG002 benchmark resources.

Large sequencing files, reference data, container images, and machine-specific configuration are not included in this repository.

## Workflow

1. **Input:** BQSR BAM files and their corresponding indexes.
2. **Variant calling:** DeepVariant generates VCF and gVCF outputs.
3. **Benchmarking:** hap.py compares query VCFs against the HG002 truth VCF within the evaluation BED regions.
4. **Reporting:** Summary and other hap.py reports are generated.

## Tools

- **Snakemake** — workflow orchestration.
- **DeepVariant** — variant calling.
- **hap.py** — benchmarking and reporting.
- **Singularity** — container execution.
- **RTG Tools** — required by hap.py when using the `vcfeval` engine.
- **BWA-MEM2** — alignment method associated with the supplied BQSR BAM filenames.

## Repository contents

| File | Purpose |
|---|---|
| `Snakefile` | Snakemake workflow |
| `config.example.yaml` | Example configuration |
| `run_deepvariant.sh` | SLURM script for DeepVariant |
| `run_benchmark.sh` | SLURM script using hap.py `vcfeval` |
| `run_benchmark_xcmp.sh` | SLURM script using hap.py `xcmp` |
| `run_dv_chr20.sh` | Additional DeepVariant helper script |
| `.gitignore` | Excludes large data, generated results, logs, and local configuration |

## Configuration

Create a local configuration file:

```bash
cp config.example.yaml config.yaml
```

Edit `config.yaml` to provide paths valid on your system, including:

- BQSR BAM files and indexes
- Reference FASTA
- DeepVariant and hap.py container images
- HG002 truth VCF and evaluation BED
- Existing DeepVariant VCF directory
- Thread and shard settings

The local `config.yaml` is excluded from version control because it contains system-specific paths.

## Dry-run

Inspect the planned workflow without executing jobs:

```bash
snakemake --snakefile Snakefile \
  --configfile config.yaml \
  --dry-run
```

To plan a single sample's benchmark:

```bash
snakemake --snakefile Snakefile \
  --configfile config.yaml \
  --dry-run \
  results/benchmark/SRR37356337.bwa_mem2.summary.csv
```

Review the DAG and input paths before running the workflow on a new system.

## Running individual SLURM scripts

The helper scripts accept a sample identifier. For example:

```bash
sbatch run_deepvariant.sh SRR37356337
sbatch run_benchmark.sh SRR37356337
sbatch run_benchmark_xcmp.sh SRR37356337
```

These scripts contain site-specific paths and SLURM settings. Update them for your environment before use. The `vcfeval` script additionally requires RTG Tools to be accessible to hap.py.

## Benchmark engines and interpretation

The repository includes scripts for two hap.py comparison engines:

- `vcfeval`
- `xcmp`

The engines use different comparison approaches. Record the engine used with every reported result, and do not treat metrics from different engines as directly interchangeable without methodological justification.

During development, the `vcfeval` run failed because RTG Tools was not available inside the hap.py container. A successful `vcfeval` result from that run has therefore not been established.

Only report metrics from completed runs whose output files and logs have been checked. Record the reference genome, truth set, evaluation regions, tool versions, and comparison engine alongside the results.

## Limitations

- The repository does not contain the raw sequencing data, BAM/VCF files, reference genome, benchmark resources, or container images.
- Input paths and container mounts must be adapted to the target computing environment.
- `vcfeval` requires a compatible RTG Tools and Java setup.
- End-to-end reproducibility should be verified on the target system before claiming that the workflow has been fully validated.

## Citation and attribution

For publications or reports based on this workflow, cite the relevant DeepVariant, hap.py, RTG Tools, and HG002 benchmark-resource publications. Add an appropriate repository license before redistributing the code.
