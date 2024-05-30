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

It has been over 14 years since the formalization of the fastq format {% cite Cock2009 %}.
It describes sequences and their quality scores.
For paired end reads, sequences are encoded in separate files, usually called R1 and R2.
Unfortunately despite the publication,
fastq format is not entirely standardized!
For example, it is possible to have a valid fastq format in either 4-line-per-entry format,
or splitting sequences into multiple lines.
Additionally, the defline itself is not entirely standardized and is basically free text.
However, we have had a lot of innovations in sequence formats since then.
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
After calling with at least Dorado, ONT sequencing outputs bam files.
[Need help here: PacBio? ]
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
One might be concerned about taking additional space,
but actually unsorted bam may offer a storage space savings over individual fastq files,
besides reduction in complexity gained by combining forward and reverse reads.

## QA/QC

Now that the files are in the repository, how do you run QA on them?
Some examples of a QA system include

* [SneakerNet](https://github.com/lskatz/SneakerNet)
* [Phoenix](https://github.com/CDCgov/phoenix)
* [Pandoo](https://github.com/schultzm/pandoo)
* [Nullarbor](https://github.com/tseemann/nullarbor)

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

For genome assembly, many labs are using Shovill.
However, Shovill does not natively read bam files.
Therefore, this workflow breaks slightly unless there is some conversion step.

Other assemblers that people commonly use for bacterial genomes are SPAdes and SKESA.
SPAdes does read bam natively and so that is good.
However, it does not appear that SKESA can read bam natively.

### MLST

MLST software usually takes fasta or fastq files.
At this point there are a million classic MLST software packages and for some additional information,
please check out Page et al 2017 {% cite Page2017 %}.
For whole genome MLST software tools, I could also not find any packages that natively read bam.
Please see [my previous blog post](https://lskatz.github.io/posts/2023/04/09/wgMLST.html) for an in depth view into three of them.
I could not find any MLST software that reads bam natively.

### Sketches

If you're like me, you want to have a directory of at least some sketches from Mash.
(see the [mashpit project](https://github.com/tongzhouxu/mashpit) for an exciting project!)
It appears that Mash natively does not read bam according to the v2.3 usage menu.
However it is promising that the Sourmash library [_does_ read bam](https://sourmash.readthedocs.io/en/latest/release-notes/sourmash-2.0.html#major-new-features-since-1-0) natively since version 2.

### Genotyping

Generally in my experience, people base genotyping on either
[KMA](https://bitbucket.org/genomicepidemiology/kma),
[SRST2](https://github.com/katholt/srst2),
[SAUTE](https://github.com/ncbi/SKESA),
or [ARIBA](https://github.com/sanger-pathogens/ariba).
Looking at each of these software packages, I could not find any documentation that bam is natively read.
However, I could find that fasta or fastq were valid inputs.
There are other software packages in the world for specific pathogens like _Salmonella_
but for this generalized blog post, I did not investigate further.

## Conclusion

The good part is that sequencing platforms output bam format natively, for what I can tell.
However, we need software to natively read these bam files.

Bioinformatics software developers should be looking ahead
to future proof their software.
They need to accept bam natively as input.
Although it might seem straightforward, there are several
links in the genomic epidemiology chain that need to be
updated.
These include updating QA/QC pipelines, primary analyses, and
secondary analyses.
I should also say that I am guilty of this.
For some of my own popular software such as 
[Mashtree](https://github.com/lskatz/mashtree/tree/master/.github/workflows)
and [Lyve-SET](https://github.com/lskatz/lyve-SET/), they do not natively read bam files!
I wish I could say that I will address this right away, but with all my other responsibilities, it will be further down the road.
Therefore I can say from my observations and my own personal experience, there is some work up ahead to get us moved over to bam files!
