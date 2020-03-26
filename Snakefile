"""Workflow for BIOINF 545 Group 1 Project
Downloads data from SRA, and quantifies with kallisto
"""
from pathlib import Path
import pandas as pd
from snakemake.remote.FTP import RemoteProvider

# Load config file into directionairy config
configfile: "config.yaml"

# Define paths
int_dir = Path(config["intermediate_dir"])
out_dir = Path(config["output_dir"])

# Load manifest
manifest = pd.read_csv(config["manifest"],sep="\t")

# Define anonymous
FTP = RemoteProvider()

rule all:
    input:
        expand(str(int_dir / "quant" / "{SRR_ID}" / "abundance.tsv"),SRR_ID=manifest["SRR"])

rule fastq_dump:
    output:
        R1 = int_dir / "fastqs" / "{SRR_ID}" / "{SRR_ID}_1.fastq.gz",
        R2 = int_dir / "fastqs" / "{SRR_ID}" / "{SRR_ID}_2.fastq.gz"
    shell:
        """
        mkdir -p $(dirname {output.R1})
        fastq-dump -O $(dirname {output.R1}) --split-files --gzip {wildcards.SRR_ID}
        """

rule kallisto_make_index:
    input: FTP.remote(config["reference"])
    output: int_dir / "reference_index.idx"
    shell:
        """
        kallisto index -i {output} {input}
        """

rule kallisto_quant:
    input:
        R1 = int_dir / "fastqs" / "{SRR_ID}" / "{SRR_ID}_1.fastq.gz",
        R2 = int_dir / "fastqs" / "{SRR_ID}" / "{SRR_ID}_2.fastq.gz",
        index = int_dir / "reference_index.idx"
    output:
        h5 = int_dir / "quant" / "{SRR_ID}" / "abundance.h5",
        abundances = int_dir / "quant" / "{SRR_ID}" / "abundance.tsv",
        run_info = int_dir / "quant" / "{SRR_ID}" / "run_info.json"
    shell:
        """
        mkdir -p $(dirname {output.h5})
        kallisto quant -i {input.index} -o $(dirname {output.h5}) {input.R1} {input.R2}
        """