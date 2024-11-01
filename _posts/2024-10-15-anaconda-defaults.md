---
layout: post
title: A Guide to the Anaconda `defaults` channel
image: /assets/images/way-of-the-mambalorian.webp

tags:
  - Conda
  - bioconda
  - conda-forge
  - defaults
contributors:
  - ammaraziz
reviewers:
- hexylena
- audy
- jfy133
- pmenzel
---

[Anaconda Inc.](https://www.anaconda.com/about-us) (the company) has begun to threaten [legal action against against commercial companies](https://www.reuters.com/legal/litigation/intel-sued-copyright-infringement-over-ai-software-2024-08-09/) and [has also advised non-profits](https://www.theregister.com/2024/08/08/anaconda_puts_the_squeeze_on/) to purchase licenses to the Anaconda software/distribution channels. While the situation is being resolved, some institutions have blocked the `anaconda.org` domain completely.

<figure class="floating">
  <img src="{% link assets/images/way-of-the-mambalorian.webp %}" alt="In the art style of 1990s Disney, cel shading: A mysterious blacksmith in a dark, forge-like setting. She wears a sleek, gold-plated helmet embossed with the symbol of a snake and an armored robe with intricate designs. Sparks fly as she hammers a molten weapon on an anvil, which begins to take the shape of a coiled snake. The forge’s flames cast a warm glow, reflecting off her helmet and tools. The snake is a python with a green sheen.">
  <figcaption>The way of the Mambalorian is miniforge distribution. This is the way.</figcaption>
</figure>

This has been brewing for a number of years. The first change happened [back in 2020](https://www.anaconda.com/blog/sustaining-our-stewardship-of-the-open-source-data-science-community), and the second happened very [recently in March 2024](https://legal.anaconda.com/policies/en/?name=terms-of-service#anaconda-terms-of-service) that affects ["government entities and non-profit entities with over 200 employees or contractors"](https://www.theregister.com/2024/08/08/anaconda_puts_the_squeeze_on/). This is problematic due the wording around 'employees' - many organisations have hundreds of employees but few users of `conda` software. 

In order to avoid any potential problems, avoiding `defaults` channel is the best course of action.

Before we dive in, a quick recap on definitions:

- [Anaconda Inc.](https://www.anaconda.com/about-us) is the commercial entity behind the `conda`, `miniconda`, and the `Anaconda.Navigator` software suite.
- Anaconda Inc. curates a set of packages which are available [through specific channels](https://repo.anaconda.com/pkgs/) - also known as `defaults` channel  
- [Miniforge](https://github.com/conda-forge/miniforge) is a non-Anaconda community-developed installer specific to `conda-forge` channel
- `mamba` is a drop in replacement to `conda`.
- Far more detailed information on all the different channels/distributions [can be found here.](https://bioconda.github.io/faqs.html#what-s-the-difference-between-anaconda-conda-miniconda-mamba-mambaforge-micromamba)

All the hoohah surrounds the [curated Anaconda channels](https://docs.anaconda.com/working-with-conda/reference/default-repositories/), commonly referred to as `defaults` channel. **Note: When installing `conda/miniconda` software, the `defaults` channel is added to your global channels list.** You could inadvertently be using Anaconda services without intending to.

## How to's

Below is guidance on how to best deal with `defaults` channel.

### Safest: Fresh Install of Miniforge distribution

1. Install the conda-forge distribution `miniforge3` - [instructions here](https://github.com/conda-forge/miniforge), this will also install `mamba`.
2. Add the channels `bioconda` and `nodefaults` [in that order] as global defaults:
  ```
  conda config --add channels bioconda nodefaults
  ```

That's it! 

### Best: Current `Miniforge` install:

**Note `miniconda` users:** The below solution is only for `miniforge` installs. See below for more details.

1. To check if your installation comes has `defaults` channel in your global configuration (regardless if that's `anaconda`, `miniconda`, `miniforge`, etc.):

  ```bash
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

4. Double check that `defaults` is not accessible, this should fail to install `anaconda-fonts`:
  ```
  # This will access defaults channel!
  conda install fonts-anaconda
  ```

If the above succeeds, see below.

Done!

### Dangerous: Conda/Miniconda

It's tricky to fully decouple your conda usage from the `defaults` channel, because it is hard-coded in some places the `miniconda` code. 

During the writing of this post, a colleague could not stop their `miniconda` installation from using the `defaults` channel, even when `defaults` was not in the channels list (we double and triple checked everything). After testing, several people also observed the same issue. We (thanks James and Helena) eventually tracked the bug to (we think) the `miniconda` + `libmamba` solver.

The conda developers have [deprecated](https://github.com/conda/conda/pull/14288) the implicit adding `defaults` and [are moving to remove it completely](https://github.com/conda/conda/issues/14217).

The safest option is to install the `conda-forge` distribution. This has the added benefit of installing `mamba` from the very beginning and is the [recommended method of installation](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) by the `mamba` devs.

To test your setup, remove the `defaults` channel (see above) try to install `fonts-anaconda`, which is accessible only via `defaults`. Warning: this will access the Anaconda defaults channel! Also check to see if you are using the `classic` or `libmamba` solver by running `conda config --show | grep "solver:"`

It is far simpler to install `miniforge3`.

### Protecting against `defaults` channel

It's possible to protect users of your pipelines/tools by including `nodefaults` channel in a `conda.yaml` file. For example:

```
channels:
  - conda-forge
  - bioconda
  - nodefaults
```

This will [override the defaults channel](https://docs.conda.io/projects/conda/en/4.6.1/user-guide/tasks/manage-environments.html#creating-an-environment-file-manually) if it exists in the users global config. Unfortunately, [this is specific to `conda env` subcommand](https://stackoverflow.com/a/67708768), therefore it will not work for `conda install` or `conda create` when added to global config. There is an open [issue](https://github.com/conda/conda/issues/12010) on github for this feature.

## FAQs + FYIs

### - How can I transition safely from `defaults` channel?

If you are worried removing `defaults` will break your current setup, `conda-forge` [has great documentation](https://conda-forge.org/docs/user/transitioning_from_defaults/) on how to test and transition from your addiction to `defaults`.

### - Be wary of foreign `conda.yaml` files in software/pipelines

Lots of pipelines/tools will use `conda.yaml` to enable easy installation of dependencies. It's very likely `defaults` could be in a `conda.yaml` file because it's been the... default to include it.

Unfortunately as far as I know, there is no setting or method available to protect against a `conda.yaml` using a package from `defaults`.

There is a feature request for `nodefaults` [to apply everywhere](https://github.com/conda/conda/issues/12010). 

I suggest always double checking foreign `conda.yaml` files before installing.

### - Will removing `defaults` interfere with the install of bioinfo tools?

Very unlikely. `conda-forge` [transitioned away](https://conda-forge.org/news/2021/09/30/defaults-channel-is-now-dropped-when-building-conda-forge-packages/) from Anaconda's `defaults` channel in 2021 and has continued to diverge in both names and recipes. There is a slight chance it may cause issues for old pre 2020/2021 recipes but this is rare as recipies have continually been updated. Not too worry though, `conda-forge` is community driven, [feel free to contribute if you run into any problems!](https://conda-forge.org/docs/user/contributing/)

Anecdotally, several people including myself have been operating without `defaults` channel for over a year. We've not had any issues. 

### - What about `bioconda` packages?

`bioconda` channel has always had strong dependencies on `conda-forge`. Therefore, dropping `defaults` will have little to no effect. If you are worried see above on how to transition from `defaults`.

### - How can I see if packages were installed from `defaults`? 

Run this command to show the source of packages in the current actived environment:

  ```
  conda list --show-channel-urls | grep "defaults"
  ```

Add `--name ENV` to inspect a specific environment without activing it.

If nothing appears, you're golden!

### - My institution has blocked `anaconda.org`. What do I do?!

`Prefix.dev`, the German company behind the all-in-one `pixi` software manager has setup mirrors of both `conda-forge` and `bioconda` channels:

```
https://prefix.dev/channels/conda-forge
https://prefix.dev/channels/bioconda
```

[Follow these instructions](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/mirroring.html
) to configure the mirrors.

### - Be careful of channel leakage

I came across this interesting issue on github [defaults channels leak into environments config](https://github.com/conda/conda/issues/12136). The summary is that due to how conda merges (*not replaces*) config files, your primary `.condarc` file could leak into other envs. More info on conda's configuration engine can be [found here](https://www.anaconda.com/blog/conda-configuration-engine-power-users) and the [documentation is here](https://docs.conda.io/projects/conda/en/latest/user-guide/configuration/use-condarc.html#conflict-merging-strategy).

Again, the safest option is to remove `defaults` from your `.condarc` (see above).

### **Questions?** Ask in the comments below!

## See Also

- Lee Katz has written a [fantastic blog](https://ubinfie.github.io/2024/10/03/pixi-basics.html) on how to use the `pixi` to do all things software related.
- Another ubinfi blogs deals with [setting up a multi-user conda installation](https://ubinfie.github.io/2024/04/02/shared-conda-tutorial.html). Check it out!
