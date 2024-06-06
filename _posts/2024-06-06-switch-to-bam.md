---
layout: post
title: What does it take to switch over to BAM from FASTQ?
tags:
  - BAM
  - uBAM
  - FASTQ
  - file formats 
contributors:
  - lskatz
  - SeanSierra-Patev
  - dbtara
reviewers:
  - pmenzel
  - hexylena 
---

It has been over 14 years since the formalization of the FASTQ format ({% cite Cock2009 %}),
which describes sequences and their quality scores.
For paired end reads, sequences are encoded in separate files, usually called R1 and R2 [^1].
Unfortunately despite the publication, FASTQ format is not entirely standardized!
For example, it is possible to have a valid FASTQ format in either 4-line-per-entry format, or splitting sequences into multiple lines.
Additionally, the defline itself is not entirely standardized and is basically free text.
However, we have had a lot of innovations in sequence formats since then.
One of those innovations is the [SAM/BAM format](https://samtools.github.io/hts-specs/), the (binary) alignment/mapping format.
While this file format is typically used to store information about alignments of sequencing reads, it can also just store the unaligned sequencing data.
Crucially, both reads from paired-end sequencing (i.e., R1 and R2) are stored in the same single file
and [it allows for metadata as explained in this GATK post](https://gatk.broadinstitute.org/hc/en-us/articles/360035532132-uBAM-Unmapped-BAM-Format).
We found at least one other [blog post with this same sentiment from _2011_](https://blastedbio.blogspot.com/2011/10/fastq-must-die-long-live-sambam.html).
This idea isn't new.
It is frustratingly old.

FASTQ files, as a means for storing primary sequencing data before any downstream analysis, are integral to genomic epidemiology.
State health labs sequence genomes,
transfer the FASTQ files to an internal repository,
run quality checks (QC), usually through a quality assurance (QA) pipeline.

**So what would it take to change this whole process to BAM files instead?**  
BAM files have many advantages including having only one file per sample instead of two,
encoding extra information such as alignment data,
and being indexed for random access.
For our purposes here, BAM files will be unaligned BAM (uBAM)
because they are not aligned against anything.

## Sequencing

First, the sequencers would have to output uBAM files.
Can they?
Illumina will not output uBAM natively, but it does allow
[Local Run Manager modules](https://customprotocolselector.illumina.com/selectors/LRM-module-selector/Content/Source/FrontPages/LRM-module-selector.htm).
If one of these modules aligns against a reference, then an Illumina platform would at least produce a BAM.
The Ion Torrent platforms do produce a uBAM automatically.
After calling with at least Dorado, ONT sequencing outputs uBAM files.
Pacbio does generate BAM as native format (they discontinued HDF5).
For platforms that do not have this automation,
we would need an easy conversion.

One such easy conversion is with `samtools`, e.g.,

```shell
samtools import -1 R1.fastq.gz -2 R2.fastq.gz --order ro -O bam,level=0 | \
  samtools sort -M - -o sorted.bam
```

## Repository

Usually the FASTQ files end up in some kind of repository, organized by
run or by organism.
Instead of FASTQ files, it is easy to imagine that now the
repository consists of the uBAM files alone.
One might be concerned about taking additional space,
but actually uBAM files may offer a storage space savings over individual FASTQ files,
besides reduction in complexity gained by combining forward and reverse reads.
The above command uses `-M` in `samtools sort`, which sorts the reads by minimizers, which allows for a much better compression and therefore reduced size of the uBAM file.
In our example dataset, we transformed a 63M R1 and 55M R2 file into an 81M unmapped sorted uBAM file.
A 31% storage reduction, in this case, can represent huge file storage savings across an entire sequencing data repository.

## QA/QC

Now that the files are in the repository, how do you run QA on them?
Some examples of a QA system include

* [SneakerNet](https://github.com/lskatz/SneakerNet)
* [Phoenix](https://github.com/CDCgov/phoenix)
* [Pandoo](https://github.com/schultzm/pandoo)
* [Nullarbor](https://github.com/tseemann/nullarbor)

Which of these pipelines can read a uBAM file?
To our knowledge, none of them!
This is one area where we need to see more adaptation of uBAM files.

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

### Assembly

For genome assembly, many labs use [Shovill](https://github.com/tseemann/shovill).
However, Shovill does not natively read uBAM files.
Therefore, this workflow breaks slightly unless there is some conversion step.

Other assemblers that people commonly use for bacterial genomes are [SPAdes](https://github.com/ablab/spades) and [SKESA](https://github.com/ncbi/SKESA).
SPAdes does read uBAM natively and so that is good.
However, it does not appear that SKESA can read uBAM natively.

### MLST

MLST software usually takes FASTA or FASTQ files.
At this point there are a million classic MLST software packages and for some additional information,
please check out {% cite Page2017 %}.
For whole genome MLST software tools, we could also not find any packages that natively read uBAM.
Please see [@lskatz's previous blog post](https://lskatz.github.io/posts/2023/04/09/wgMLST.html) for an in depth view into three of them.

### Sketches

If you're like us, you want to have a directory of at least some sketches from Mash.
(see the [mashpit project](https://github.com/tongzhouxu/mashpit) for an exciting project!)
It appears that Mash natively does not read uBAM according to the v2.3 usage menu.
However it is promising that the [Sourmash](https://github.com/sourmash-bio/sourmash) library [_does_ read uBAM](https://sourmash.readthedocs.io/en/latest/release-notes/sourmash-2.0.html#major-new-features-since-1-0) natively since version 2.

### Genotyping

Generally in our experience, people base genotyping on either
[KMA](https://bitbucket.org/genomicepidemiology/kma),
[SRST2](https://github.com/katholt/srst2),
[SAUTE](https://github.com/ncbi/SKESA),
or [ARIBA](https://github.com/sanger-pathogens/ariba).
Looking at each of these software packages, we could not find any documentation that uBAM is natively read.
However, we could find that FASTA and FASTQ were valid inputs.
There are other software packages in the world for specific pathogens like _Salmonella_
but for this generalized blog post, we did not investigate further.

## Other compression methods

This article discusses the uBAM format, but there have been many attempts over the years to make other compression formats [^2].
The [CRAM format](https://samtools.github.io/hts-specs/CRAMv3.pdf) is probably the best example.
CRAM has an even better lossless compression of sequences than uBAM,
and we even confirmed it on our own sequence.

```bash
samtools import -1 1.fastq.gz -2 2.fastq.gz --order ro -O bam,level=0 | \
  samtools sort -O cram --output-fmt-option archive -M - -o archive.cram
```

When viewing the same sequences in FASTQ, BAM, or CRAM, we get an astonishing reduction.

```text
-rw-------. 1 user users 81M May 30 20:03 unmapped.bam
-rw-------. 1 user users 55M May 31 09:18 unmapped.cram
-rw-------. 1 user users 55M Dec  6  2019 1.fastq.gz
-rw-------. 1 user users 63M Dec  6  2019 2.fastq.gz
```

The CRAM format is seemlessly incorporated into samtools, allowing for freely converting between formats.
In fact, [EBI stores a ton of CRAM files already](https://x.com/BonfieldJames/status/1182180199657607168).
So why wouldn't we recommend CRAM upfront?
Probably because it is a bigger lift that would involve convincing many sequencing companies to adopt it.
We can check a box on our nanopore that makes BAMs; we can't do the same for CRAM.
That said, given an ideal world, we would encourage the sequencing companies to consider that check box.

## Conclusion

The good part is that many but not all sequencing platforms output uBAM format natively.
For those that don't have this capability, we have a way to convert FASTQ to uBAM.
However even after aquiring a uBAM, we need software to natively read them.

Bioinformatics software developers should be looking ahead
to future proof their software.
They need to accept uBAM natively as input.
Although it might seem straightforward, there are several
links in the genomic epidemiology chain that need to be
updated.
These include updating QA/QC pipelines, primary analyses, and
secondary analyses.
As for @lskatz, I should also say that I am guilty of this.
For some of my own popular software such as
[Mashtree](https://github.com/lskatz/mashtree/tree/master/.github/workflows)
and [Lyve-SET](https://github.com/lskatz/lyve-SET/), they do not natively read uBAM files!
I wish I could say that I will address this right away, but with all my other responsibilities, it will be further down the road.
Therefore we can say from our own observations and personal experience, there is some work up ahead to get us moved over to uBAM files!

[^1] To maintain focus in this article, I will gloss past interleaved reads.
[^2] One such example of an organization trying to standardize is [here](https://www.genomeweb.com/informatics/will-bioinformatics-professionals-embrace-mpeg-g-data-compression-standard?utm_source=addthis_shares#.XcwmeiO9qjW.twitter).
