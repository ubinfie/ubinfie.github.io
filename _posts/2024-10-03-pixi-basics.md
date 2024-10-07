---
layout: post
title: Pixi basics
date: 2024-10-03 15:00:00
author: "Lee Katz"
tags:
  - development
  - conda
  - bioconda
  - software
  - pixi
contributors:
  - lskatz
reviewers:
- samuell
- ammaraziz
- rpetit3
---

Recently I had an issue where Conda was no longer a viable solution
for my day to day.
Namely 1) the defaults channel was becoming a for-pay model and 2) the actual site anaconda.org was being blocked at work.

Pixi is an alternative to conda where it is really easy to remove the defaults channel and where it is a slightly different model:
Each time you "activate" the environment, it is actually an environment meant for that specific directory.
Therefore, a project can have a designated environment that gets activated with `pixi init` when you or a collaborator enter the directory and wants to get started.

Also, the whole thing is written in Rust which I really really respect for stability and speed.

## Starting off

The only way I can think of how to show this off properly is to get a real example.
I'll choose a random software package hmmm.... `mashtree`?
### Installation

Pixi can be installed following [instructions on their website](https://pixi.sh/latest/)

### Configuring

First, if you are running this on RHEL8 like me, you have a few things to change: 1) remove the anaconda defaults channel and 2) account for RHEL8 (or other older operating systems).

First, start off the config file in your user space. It lives in `~/.config/pixi`. _Note_: you can have [system-wide configs or local configs](https://pixi.sh/latest/reference/pixi_configuration/)
but I will leave that outside the scope of this post.

```bash
mkdir -pv ~/.config/pixi
# paste in these contents with `cat` and then ctrl-D to end the paste
cat > ~/.config/pixi/config.toml
# or just open a blank file ~/.config/pixi/config.toml with, e.g., nano or vim, and paste in these contents
```

```text
default-channels = ["conda-forge", "bioconda"]

[mirrors]
"https://conda.anaconda.org" = [
  "https://prefix.dev/"
]
```

Next, if you have RHEL8 like I do, then your kernel is older and so
you have to keep this in mind.
The following toml snippet would have to be added at the end of any of your `pixi.toml` files.

```toml
[system-requirements]
linux = "3"
libc = { family = "glibc", version = "2.0" }
```

This pins the Linux kernel to version 3 and the glibc library to version 2.0.

### pixi init

Next, go to your project directory and run `pixi init`.

```bash
mkdir -p ~/projects/mashtree-pixi
cd ~/projects/mashtree-pixi
pixi init
# Then, optionally add in the above toml that starts with `[system-requirements]`
cat >> pixi.toml
# [paste, ctrl-D]
```

### Install

Installation is way faster than Conda.
It is in two steps.
First, you `add` and then you `install`.

```bash
pixi add mashtree
✔ Added mashtree >=1.4.6,<2
```

But at this point, no software has been installed.
Instead, it just has a new entry in `pixi.toml` that shows the solved versions.

```toml
[dependencies]
mashtree = ">=1.4.6,<2"
```

Let's complicate it a bit more by adding unrelated software.

```bash
pixi add samtools bedtools fasten
✔ Added samtools >=1.20,<2
✔ Added bedtools >=2.31.1,<3
✔ Added fasten >=0.8.3,<0.9
```

and then the related toml expands to

```toml
[dependencies]
mashtree = ">=1.4.6,<2"
samtools = ">=1.20,<2"
bedtools = ">=2.31.1,<3"
fasten = ">=0.8.3,<0.9"
```

Great, let's install it!

```bash
pixi install
✔ The default environment has been installed.
```

## Run stuff from pixi

At this point, you or another person can go into this directory and run things from pixi.
The easiest thing is to run `pixi shell` which actually starts a new shell.
To exit, run `exit` like you normally would from a subshell (or ctrl-D!).
No more `conda deactivate` nonsense.

```bash
pixi shell
which samtools
# => $PWD/envs/default/bin/samtools
cd ..
which samtools 
# => returns the same path
cd - 
# get back to where you were
exit # to exit the pixi shell
```

Or, if you just want to run one thing outside of the `pixi shell`:

```bash
pixi run samtools tview
Usage: samtools tview [options] <aln.bam> [ref.fasta]
Options:
   -d display      output as (H)tml or (C)urses or (T)ext 
   -X              include customized index file
   -p chr:pos      go directly to this position
   -s STR          display only reads from this sample or group
   -w INT          display width (with -d T only)
      --input-fmt-option OPT[=VAL]
               Specify a single input file format option in the form
               of OPTION or OPTION=VALUE
      --reference FILE
               Reference sequence FASTA FILE [null]
      --verbosity INT
               Set level of verbosity
```

You can even go into a subfolder and run `pixi run samtools tview` to get the same output!

## Benchmarking

I wanted to benchmark this specifically for bioinformatics and so I took a list of the most popular software from the [StaPH-B Docker builds](https://hub.docker.com/u/staphb):

* fastqc
* bcftools
* samtools
* vadr
* ska
* pangolin
* ivar

I benchmarked installation and removal of all of these software packages at once and then one at a time for a total of 8 tests.
For benchmarking, I used the `hyperfine` project.
For Conda, I used [miniforge](https://github.com/conda-forge/miniforge) v24.7.1-2 which uses the libmamba solver.

Essentially, for conda it runs `conda create` followed by `rm -rf` to delete the environment. For pixi, it runs `pixi add`, `pixi install`, and then `pixi remove`.
Then, it compares the average times.

<details>
  <summary>
    Here is the actual script.
  </summary>

```bash
#!/bin/bash

PACKAGES="fastqc bcftools samtools vadr ska pangolin ivar"
RUNS=4
WARMUP=1

# Install all packages
hyperfine \
    --warmup $WARMUP \
    --runs $RUNS \
    --show-output \
    "pixi add $PACKAGES && pixi install && pixi remove $PACKAGES" \
    "conda create -y -p condaenv $PACKAGES && rm -rf condaenv"  

# Install each package individually
for package in $PACKAGES; do
    hyperfine \
        --warmup $WARMUP \
        --runs $RUNS \
        --show-output \
        "pixi add $package && pixi install && pixi remove $package" \
        "conda create -y -p condaenv $package && rm -rf condaenv"
done
```

</details>

<details>

  <summary>
    Pixi created an environment faster than conda. Click for details.
  </summary>

```text
Benchmark 1: pixi add fastqc bcftools samtools vadr ska pangolin ivar && pixi install && pixi remove fastqc bcftools samtools vadr ska pangolin ivar

  Time (mean ± σ):     186.445 s ±  4.742 s    [User: 51.461 s, System: 131.253 s]
  Range (min … max):   182.610 s … 193.372 s    4 runs
 
Benchmark 2: conda create -y -p condaenv fastqc bcftools samtools vadr ska pangolin ivar && rm -rf condaenv

  Time (mean ± σ):     411.287 s ±  6.462 s    [User: 44.182 s, System: 49.567 s]
  Range (min … max):   403.955 s … 417.558 s    4 runs
 
Summary
  'pixi add fastqc bcftools samtools vadr ska pangolin ivar && pixi install && pixi remove fastqc bcftools samtools vadr ska pangolin ivar' ran
    2.21 ± 0.07 times faster than 'conda create -y -p condaenv fastqc bcftools samtools vadr ska pangolin ivar && rm -rf condaenv'

Benchmark 1: pixi add fastqc && pixi install && pixi remove fastqc

  Time (mean ± σ):     39.911 s ±  0.811 s    [User: 14.458 s, System: 18.381 s]
  Range (min … max):   39.335 s … 41.098 s    4 runs
 
Benchmark 2: conda create -y -p condaenv fastqc && rm -rf condaenv

  Time (mean ± σ):     74.445 s ±  0.539 s    [User: 10.369 s, System: 10.453 s]
  Range (min … max):   73.916 s … 75.187 s    4 runs
 
Summary
  'pixi add fastqc && pixi install && pixi remove fastqc' ran
    1.87 ± 0.04 times faster than 'conda create -y -p condaenv fastqc && rm -rf condaenv'

Benchmark 1: pixi add bcftools && pixi install && pixi remove bcftools

  Time (mean ± σ):     38.168 s ±  0.514 s    [User: 11.245 s, System: 16.516 s]
  Range (min … max):   37.677 s … 38.873 s    4 runs
 
Benchmark 2: conda create -y -p condaenv bcftools && rm -rf condaenv

  Time (mean ± σ):     54.631 s ±  0.446 s    [User: 8.291 s, System: 7.429 s]
  Range (min … max):   54.182 s … 55.248 s    4 runs
 
Summary
  'pixi add bcftools && pixi install && pixi remove bcftools' ran
    1.43 ± 0.02 times faster than 'conda create -y -p condaenv bcftools && rm -rf condaenv'

Benchmark 1: pixi add samtools && pixi install && pixi remove samtools

  Time (mean ± σ):     24.693 s ±  0.831 s    [User: 7.415 s, System: 8.035 s]
  Range (min … max):   24.182 s … 25.921 s    4 runs
 
Benchmark 2: conda create -y -p condaenv samtools && rm -rf condaenv

  Time (mean ± σ):     35.740 s ±  0.770 s    [User: 6.519 s, System: 5.505 s]
  Range (min … max):   34.609 s … 36.290 s    4 runs
 
Summary
  'pixi add samtools && pixi install && pixi remove samtools' ran
    1.45 ± 0.06 times faster than 'conda create -y -p condaenv samtools && rm -rf condaenv'

Benchmark 1: pixi add vadr && pixi install && pixi remove vadr

  Time (mean ± σ):     70.947 s ±  0.554 s    [User: 23.427 s, System: 37.370 s]
  Range (min … max):   70.519 s … 71.733 s    4 runs
 
Benchmark 2: conda create -y -p condaenv vadr && rm -rf condaenv

  Time (mean ± σ):     127.758 s ±  7.067 s    [User: 18.144 s, System: 16.139 s]
  Range (min … max):   122.523 s … 137.886 s    4 runs
 
Summary
  'pixi add vadr && pixi install && pixi remove vadr' ran
    1.80 ± 0.10 times faster than 'conda create -y -p condaenv vadr && rm -rf condaenv'

Benchmark 1: pixi add ska && pixi install && pixi remove ska

  Time (mean ± σ):      5.076 s ±  0.149 s    [User: 5.854 s, System: 1.689 s]
  Range (min … max):    4.948 s …  5.283 s    4 runs
 
Benchmark 2: conda create -y -p condaenv ska && rm -rf condaenv

  Time (mean ± σ):      8.831 s ±  0.466 s    [User: 4.585 s, System: 2.413 s]
  Range (min … max):    8.215 s …  9.262 s    4 runs
 
Summary
  'pixi add ska && pixi install && pixi remove ska' ran
    1.74 ± 0.10 times faster than 'conda create -y -p condaenv ska && rm -rf condaenv'

Benchmark 1: pixi add pangolin && pixi install && pixi remove pangolin

  Time (mean ± σ):     160.734 s ±  5.329 s    [User: 41.234 s, System: 105.102 s]
  Range (min … max):   154.892 s … 167.771 s    4 runs
 
Benchmark 2: conda create -y -p condaenv pangolin && rm -rf condaenv

  Time (mean ± σ):     321.362 s ±  5.470 s    [User: 31.665 s, System: 39.065 s]
  Range (min … max):   315.114 s … 328.384 s    4 runs
 
Summary
  'pixi add pangolin && pixi install && pixi remove pangolin' ran
    2.00 ± 0.07 times faster than 'conda create -y -p condaenv pangolin && rm -rf condaenv'
Benchmark 1: pixi add ivar && pixi install && pixi remove ivar

  Time (mean ± σ):     24.782 s ±  0.354 s    [User: 7.629 s, System: 7.915 s]
  Range (min … max):   24.505 s … 25.275 s    4 runs
 
Benchmark 2: conda create -y -p condaenv ivar && rm -rf condaenv

  Time (mean ± σ):     37.005 s ±  0.452 s    [User: 6.882 s, System: 5.673 s]
  Range (min … max):   36.575 s … 37.606 s    4 runs
 
Summary
  'pixi add ivar && pixi install && pixi remove ivar' ran
    1.49 ± 0.03 times faster than 'conda create -y -p condaenv ivar && rm -rf condaenv'

```

</details>

For the complicated installation, pixi is 2.21x faster than conda.
For individual installations, it is consistently more than 1.4x faster than conda.

## Day to day operations

Why would you even go through all this?
If you have read this post up to here, I am guessing that you already use conda and do not appreciate being told to fix what isn't broken.

Instead, consider that there could be times when it is way more appropriate to use pixi.
For example, let's say that you are working in a project folder where you make your own "lab notebook" with markdown.
The project is simple; it is reads mapped to a reference genome.

What were your methods? Your lab notebook/readme says that you downloaded `SRR123` using `fastq-dump`, downloaded `NC_123`, and then mapped the reads with `bwa`. Finally, you sorted and indexed your bam file with `samtools`.

In most of our notebooks, we might have forgotten to specify what software we used or maybe what versions.
The most careful of us might have had a conda environment file.
The 0.01% of us might have even been careful enough to save the environment into the actual project folder.

However, with pixi, the environment creation is fast enough that you don't have to save it forever in your project folder.
The initialization is folder/project based too -- it is simple enough to write into your notebook to start with `pixi shell` and to have the `pixi.toml` file as part of your project.
This workflow gets much better if you are in a collaborative environment with multiple hands on the same folder.
Activating the correct environment is pretty much fail-safe because the folder itself dictates the environment.
Or, dare to imagine, packaging up an entire project directory with its dependency software in a single toml file.

That is all to say that I don't think that there is a definitive reason to switch to pixi -- I think it just flows better.
The same way that you start off a development project with `git init`.

## Caveats

There are many caveats to switching over from conda.
In fact, there is a [whole article](https://pixi.sh/latest/switching_from/conda/) about it.
Here are some noteworthy caveats.

* Python itself should be added to the dependencies section, e.g.,

```toml
[dependencies]
python = ">=3.9"
```

* pip requirements can be added under the `[project]` section, e.g.,

```toml
[project]
dependencies = [
    "numpy",
    "pandas",
    "matplotlib",
]
```

* Specifically for Python, you can specify the required version with `requires-python` like so:

```toml
[project]
requires-python = ">=3.9"
```

* Adding pypi packages on the command line is straightforward too, e.g.,

```bash
# allows you to add a library to your python script, e.g., 
#   from rich import print
pixi add --pypi rich
```
