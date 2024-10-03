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

### Configuring

First, if your system is like mine, you have a few things to change:
remove anaconda and account for an older system.

First, start off the config file. It lives in `~/.config/pixi`

```bash
mkdir -pv ~/.config/pixi
# paste in these contents with `cat` and then ctrl-D to end the paste
cat > ~/.config/pixi/config.toml
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
To exit, run `exit` like you normally would from a subshell.
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
