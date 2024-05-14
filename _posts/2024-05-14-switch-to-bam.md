---
layout: post
title: What does it take to switch over to bam from fastq?
tags:
  - bam
  - fastq 
contributors:
  - lskatz
  - SeanSierra-Patev
reviewers:

---

It has been over XX years since the formalization of the fastq format.
It describes sequences and their quality scores.
For paired end reads, sequences are encoded in separate files, usually called R1 and R2.
However, we have had a lot of innovations in sequence quality since then.
One of those innovations is the BAM format which is the binary alignment/mapping format.
R1 and R2 are encoded in the same file.

Fastq files are integral to genomic epidemiology.
State health labs sequence genomes,
transfer the fastq files to an internal repository,
run quality checks (QC), usually through a quality assurance (QA) pipeline.

**So what would it take to change this whole process to bam files instead?**
Bam files have many advantages including having one file per sample,
encoding extra information such as alignment data,
and being indexed for random access.
For our purposes here, bam files will be unaligned bam (uBAM)
because they are not aligned against anything.

## Sequencing

First, the sequencers would have to output bam files.
Can they?
The Illumina platforms and the Ion Torrent platforms do automatically.
[Need help here: PacBio? ONT?]
For platforms that do not have this automation,
we would need an easy conversion.

One such easy conversion is with `samtools`, e.g.,

```shell
samtools import -1 R1.fastq.gz -2 R2.fastq.gz --order ro -O bam,level=0 | \
  samtools sort - -o sorted.bam
# optionally, index
samtools index sorted.bam
```

## Repository

Usually the fastq files end up in some kind of repository, organized by
run or by organism.
Instead of fastq files, it is easy to imagine that now the 
repository consists of the bam files alone.

## QA/QC

Now that the files are in the repository, how do you run QA on them?
Some examples of a QA system include

* SneakerNet
* Phoenix
* Pandoo
* Nullarbor

Which of these pipelines can read a bam file?
To my knowledge, none of them! [Need help here: is this correct?]
This is one area where we need to see more adaptation of bam files.

## Primary analysis

There are several primary analyses that can be performed
right after QA/QC.
For example, reads might need to be transformed into an assembly.
Or also, they might need to have multilocus sequence typing (MLST)
run so that all alleles are known in future comparisons.
Some labs are sketching genomes as they are sequenced
and so certain tools can create those sketches.
Finally, there might be individual genotyping operations
such as Salmonella serotyping or virulence factors detection.

### assembly

Which assembly methods can read bam files?

### MLST

What takes bams?

### Sketches

Mash, etc

### Genotyping

What takes bams?

Salmonella genotyping?

E. coli serogrouping?

## Secondary analysis

This is the stage of where we start seeing exciting things.
What does the sample cluster with?
We have a few methods out there that read assemblies.
If they do, then that's fine because we have already used 
the bam files to create an assembly at this point.
If they use reads, then we'll need to make sure that these
methods can read bam.

### kmer

Mashtree

SKA

KSNP4

### MLST clustering

### SNP analysis

