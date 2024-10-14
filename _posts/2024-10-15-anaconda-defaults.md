---
layout: post
title: Ananconda, defaults, and how to not get sued

date: 2024-10-15 00:00:00
author: "Ammar Aziz"
tags:
  - anaconda
  - conda
  - bioconda
  - software
contributors:
  - ammarziz
reviewers:
- TBA
---

# Guide to Ananconda `defaults` channel

**tldr:** Run these commands:

```
conda config --show channels
conda config --remove channels defaults
conda config --show channels
```

## Background

Ananconda Inc has started to threaten [legal action against against commercial companies](https://www.reuters.com/legal/litigation/intel-sued-copyright-infringement-over-ai-software-2024-08-09/) and [has also advised non-profits](https://www.theregister.com/2024/08/08/anaconda_puts_the_squeeze_on/) to purchase licenses to the anaconda software/distribution channels. While the situation is being resolved, some institutions have blocked the `anaconda.org` domain completely.

This has been brewing for a number of years. The first change happened [back in 2020](https://www.anaconda.com/blog/sustaining-our-stewardship-of-the-open-source-data-science-community), and the second happened very [recently in March 2024](https://legal.anaconda.com/policies/en/?name=terms-of-service#anaconda-terms-of-service) that affects non profit organisations ["government entities and non-profit entities with over 200 employees or contractors"](https://www.theregister.com/2024/08/08/anaconda_puts_the_squeeze_on/). This is problematic due the wording around 'employees' - many organisations have hundreds of employees but few users of `conda` software.

Before we dvice in, a quick recap definitions:

- Anaconda Inc is the comerical entity behind the `conda` and `miniconda` software and the `Anaconda.Navigator` software suite.
- Anaconda has curated packages which are available [through specific channels](https://repo.anaconda.com/pkgs/)  
- `Miniforge` is a non-Anaconda installer specific to `conda-forge` channel, 
- `mamba` is a drop in replacement to `conda`.
- Far more detailed information on all the different channels/distributions [can be found here.](https://bioconda.github.io/faqs.html#what-s-the-difference-between-anaconda-conda-miniconda-mamba-mambaforge-micromamba)

All the hooha surrounds the [curated Ananconda channels](https://docs.anaconda.com/working-with-conda/reference/default-repositories/), the primary one being the `defaults` channel. **When installing `conda/miniconda` software, the `defaults` channel is added to your global channels list.** You cond inadvertantly be using Anaconda services without intending to.

## How to's

Below is guidance on how to best deal with `defaults` channel.

### Fresh Install - Best practices

1. Install `miniforge` conda-forge specific distrubtion  - [instructions here](https://github.com/conda-forge/miniforge), this will also install mamba.
2. Add the channels `bioconda` and `nodefaults` [in that order] as global defaults
```
conda config --add channels bioconda nodefaults
```
That's it!

### Current install - Remove `defaults`:

1. To check if your installation has `defaults` channel in your global configuration:

```
conda config --show channels
# or more informative: 
conda config --get
```

2. Now remove `defaults`:
```
conda config --remove channels defaults
```

3. Check `defaults` is removed:
```
conda config --show channels
```
Done!

### Protecting against `defaults` channel

It's possible to protect users of your pipelines/tools by including `nodefaults` channel in a `conda.yaml` file. For example:

```
channels:
  - conda-forge
  - bioconda
  - nodefaults
```

This will [override the defaults channel](https://docs.conda.io/projects/conda/en/4.6.1/user-guide/tasks/manage-environments.html#creating-an-environment-file-manually) if it exists in the users global config. Unfortunately, [this is specific to `conda env` subcommand](https://stackoverflow.com/a/67708768), therefore it will not work for `conda install` or `conda create` when added to global config. There is an issue on github for this feature.

### Possible FAQs

- What happens if a `conda.yaml` file contains the `defaults` channel?

As far as I know, there is no setting available to protect against this. There is a feature request for `nodefaults` [to apply everywhere](https://github.com/conda/conda/issues/12010). 

I suggest always double checking foreign `conda.yaml` files before installing.

- Will removing `defaults` interfere with with any bioinformatics packages?

Unlikely. `conda-forge` [transitioned away](https://conda-forge.org/news/2021/09/30/defaults-channel-is-now-dropped-when-building-conda-forge-packages/) from Anaconda's `defaults` channel in 2021 and has continued to diverge in both names and recipes. There is a slight chance it may cause issues for old pre 2020/2021 recipes but this is rare as recipies have continually been updated. Not too worry though, `conda-forge` is community driven, [feel free to contribute!](https://conda-forge.org/docs/user/contributing/)

Anecdotally, several people including myself have been operating without `defaults` channel for over a year. We've not had any issues. 

- How can I transition safely from `defaults` channel?

If you are worried it will break your setup, `conda-forge` [has great documentation](https://conda-forge.org/docs/user/transitioning_from_defaults/) on how to test and transition from your addiction to `defaults`.

- What about `bioconda` packages?

`bioconda` channel has always had strong dependencies on `conda-forge`. Therefore, dropping `defaults` will have little to no effect. If you are worried see above on how to transition from `defaults`.

- How can I see if packages are installed from `defaults`? 

Run this command:

```
conda list --show-channel-urls | grep "defaults"
```

If nothing appears, you're golden!

- My institution has blocked `anaconda.org`. What do I do?!

`Prefix.dev`, the German company behind the all-in-one `pixi` software manager has setup mirrors of both `conda-forge` and `bioconda` channels:

```
https://prefix.dev/channels/conda-forge
https://prefix.dev/channels/bioconda
```
[Follow these instructions](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/mirroring.html
) to configure the mirrors. 

Questions? Ask in the comments below!

### See Also

- The amazing Lee Katz has written a [fantastic blog](https://ubinfie.github.io/2024/10/03/pixi-basics.html) on how to use the `pixi` to do all things software related.
- Related: [An ideal setup for a multi-user conda installation](https://ubinfie.github.io/2024/04/02/shared-conda-tutorial.html)