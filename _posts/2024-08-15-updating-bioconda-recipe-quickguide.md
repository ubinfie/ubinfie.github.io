---
layout: post
title: Updating bioinformatic software on Bioconda - a reference guide
author: "James A. Fellows Yates"
tags:
  - development
  - conda
  - bioconda
  - software
contributors:
  - jfy133
---

In this second part of a three part guide, this post aims to provide an (opinionated) guide on how to update an existing tool or package that is already on Bioconda.

- _For part one of this guide, see [adding a new tool or package to Bioconda](adding-to-bioconda-quickguide)._
- _For part three of this guide, see [debugging a Bioconda build](debugging-bioconda-build-quickguide)._

The [conda package manager](https://docs.conda.io/en/latest/) combined with the [Bioconda](https://bioconda.github.io/) repository has become a _de facto_ gold-standard way for distributing bioinformatics software ({% cite Gruening2018 %}).
The associated [Biocontainer](https://biocontainers.pro/) project serves to provide complementary Docker and Singularity containers from the same conda ({% cite Da_Veiga_Leprevost2017 %}).

Updating a Bioconda recipe is often a relatively easy process as much of the 'hard work' and problems has been solved in the initial recipe creation.
Typically updates to a Bioconda recipe consist of updating the version number of the tool and the hash of the tool or packages source code tarball.
In some cases you may need to add a few dependencies (easy), and in rare cases change the build process (more complex). However in all cases you can refer to [part one of this guide](adding-to-bioconda-quickguide) to understand these more complex scenarios.

In general however the process for updating or fixing an existing recipe the process is similar to the later steps in [adding a new tool or package](adding-to-bioconda-quickguide).

_Note that if we use GitHub releases for our tool/package, Bioconda tries to \_automatically_ update Bioconda recipes for us, so we may not need to do many of the steps this manually.\_
_Of course, this works if there are no changes to the dependencies or tests that can cause the tests and thus the recipe building to fail._

## Prerequisite

Make sure to familiarise yourself [part one](adding-to-bioconda-quickguide) of this three part guide to understand the basics of adding a new tool to Bioconda.

## Updating a Bioconda recipe

Otherwise, to manually update or fix a recipe:

1. Make sure our `bioconda-recipes` fork is up to date with the main.
2. Make a new branch for the update.
3. Edit the `meta.yaml`, `build.sh` files of the recipe with our changes.
4. Update the build number:

   - If it is simply _fixing_ a recipe with no version change of the tool, bump the `build_number` by `+1`.
   - If this is a new version of the tool, set the `build_number` to `0`.

   For most updates, the differences would simply look like this in the `meta.yaml` file:

   {% raw %}

   ```diff
   - {% set version = "2.0.6" %}
   + {% set version = "2.0.7" %}

   package:
       name: cami-amber
       version: {{ version }}

   source:
       url:  https://pypi.io/packages/source/c/cami-amber/cami-amber-{{ version }}.tar.gz
   -  sha256: d2d3d13a135f7ce4dff6bc1aab014945b0e5249b02f9afff3e6df1d82ef45d5a
   +  sha256: 01f11fbab7cb0f24497932669b00981292b1dc0df2ce6cd4b707a7ddd675bf8d

   build:
       noarch: python
   ```

   {% endraw %}

5. Add all files, commit and push to our fork.
6. Open the PR on `bioconda-recipes`, wait for the CI to to complete successfully, and tag for review with '@BiocondaBot please add label' as above.
   - If something goes wrong and something does not complete successfully, check the hash and build numbers are correct
   - If linting goes wrong, this is typically related to a missing `run_exports` section, see the opening instructions on the [`pango-collapse` PR](https://github.com/bioconda/bioconda-recipes/pull/50377).

In case something goes wrong during step 6 above, see [part three of this guide](debugging-bioconda-build-quickguide) on how to debug a Bioconda build in case something goes wrong.
If the tool needs a new build procedure, see [part one of this guide](adding-to-bioconda-quickguide) for more information on how to write `build.sh` scripts.

## Conclusion

This part three of this guide, we given you enough pointers for anyone to be able to update an existing Bioconda recipe.

In the [second part](updating-bioconda-recipe-quickguide) of this guide, we will go through how to update an existing recipe.
In the [third part](debugging-bioconda-build-quickguide), we will go through how to manually debug the build process if things go wrong.

As with all bioinformatics and software development in general, things rarely just 'work' straight out of the box.
My three biggest points of advice:

- Always copy and paste from other similar tools or packages on the Bioconda recipes repository.
- Take the time to read through the whole log messages (sometimes you can find critical clues hidden amongst the verbose information).
- Take the time to go step by step trying to follow exactly what Bioconda does during it's own building on Azure with local building.

I found by taking the time, I very quickly learnt common issues and how to solve them.

Worst comes to worst, you can always ask the very friendly Bioconda team on the [Bioconda gitter/matrix channel](https://gitter.im/bioconda/Lobby).
