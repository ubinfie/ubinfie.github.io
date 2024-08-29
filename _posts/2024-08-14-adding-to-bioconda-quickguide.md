---
layout: post
title: Adding bioinformatic software to Bioconda - a reference guide
author: "James A. Fellows Yates"
tags:
  - development
  - conda
  - bioconda
  - software
contributors:
  - jfy133
---

This post aims to provide an (opinionated) guide to adding a tool to Bioconda, and how to debug Bioconda and the associated Biocontainer builds.

The [conda package manager](https://docs.conda.io/en/latest/) combined with the [Bioconda](https://bioconda.github.io/) repository has become a _de facto_ gold-standard way for distributing bioinformatics software ({% cite Gruening2018 %}).
The associated [Biocontainer](https://biocontainers.pro/) project serves to provide complementary Docker and Singularity containers from the same conda ({% cite Da_Veiga_Leprevost2017 %}).

While the Bioconda team has provided a huge amount of impressive infrastructure to make adding our bioinformatic tools and packages to the repository as easy as possible, the documentation is lacking at points.
In particular, while the [Bioconda documentation](https://bioconda.github.io/contributor/index.html) explains nicely how to contribute to the repository, I personally found that it misses out on the important part of how to make what we _actually_ will add i.e, how to _make_ the [conda recipe](https://docs.conda.io/projects/conda-build/en/latest/concepts/recipe.html) specifically for Bioconda [^1]. Another thing I found particularly tricky is how to debug the build process if things go wrong.

I hope to here provide guidance, based on my personal experience, to people who are interested in adding their software to Bioconda but maybe felt it too overwhelming to start.
Hopefully it will provide sufficient 'hand-holding' to get us through the process, after which it's just 'rinse and repeat'!

The main sections of this post are:

- TL;DR
- Prerequisites
- Adding a new tool or package
- Debugging a recipe build
- Updating an existing tool or package recipe

Please note that this post comes with 'no warranty'!(!), as the Bioconda build steps could change at any point.
However, the steps here should act as a good starting point.
Furthermore, if you are planning to add someone else's tool or package to Bioconda, it's always good etiquette to ask or just inform the original authors that it will happen.

_I would like to thank George Bouras (@gbouras13) for prompting the formalisation of my rough notes that he shared on Twitter where it became more popular than I expected._

## TL;DR

### Overview

![Overview diagram of the steps of the steps described in this post.]({% link assets/images/2024-08-14-bioconda-guide/bioconda-guide-workflowdiagram_short.svg %})

### Relevant Commands

```bash
## Create environment with conda building tools
conda create -n bioconda-build -c conda-forge -c bioconda conda-build bioconda-utils greyskull
conda activate bioconda-build

## Clone repo of your fork of https://github.com/bioconda/bioconda-recipes and make branch
git clone <your-forked-bioconda-recipes-repo-address>
git switch -c add-<toolname>

## Make recipe meta.yaml
   ## Option 1: If using Greyskull
   cd recipes/
   greyskull <pypi/cran> > <toolname>/meta.yaml

   ## Option 2: If not using Greyskull
   mkdir recipes/<toolname>
   touch recipes/<toolname>/meta.yaml

## Lint recipe meta.yaml
bioconda-utils lint recipes/ --packages pathphynder

## Perform a local build (two options)
   ## Option 1:
   conda build recipes/<toolname>

   ## Option 2:
   bioconda-utils build --docker --mulled-test --packages <toolname>

## Debugging
   ## Option 1: conda-build
   cd /<path>/<to>/<conda-install>/envs/<toolname>/conda-bld/linux-64
   conda create -n <debugging-env-name> -c ./ <tool_name_as_in_recipe>
   conda build recipes/<toolname> --keep-old-work

   ## Option 2: bioconda-utils
   docker run -t --net host --rm -v /tmp/tmp<randomletters>/build_script.bash:/opt/build_script.bash -v /<path>/<to>/<conda-install>/envs/<toolname>/conda-bld/:/opt/host-conda-bld -v /<path>/<to>/<recipes_local_clone>/recipes/<toolname>:/opt/recipe -e LC_ADDRESS=en_GB.UTF-8 -e LC_NAME=en_GB.UTF-8 -e LC_MONETARY=en_GB.UTF-8 -e LC_PAPER=en_GB.UTF-8 -e LANG=en_GB.UTF-8 -e LC_IDENTIFICATION=en_GB.UTF-8 -e LC_TELEPHONE=en_GB.UTF-8 -e LC_MEASUREMENT=en_GB.UTF-8 -e LC_TIME=en_GB.UTF-8 -e LC_NUMERIC=en_GB.UTF-8 -e HOST_USER_ID=1000 quay.io/bioconda/bioconda-utils-build-env-cos7:2.11.1 bash

   conda mambabuild -c file:///opt/host-conda-bld --override-channels --no-anaconda-upload -c conda-forge -c bioconda -c defaults -e /opt/host-conda-bld/conda_build_config_0_-e_conda_build_config.yaml -e /opt/host-conda-bld/conda_build_config_1_-e_bioconda_utils-conda_build_config.yaml /opt/recipe/meta.yaml 2>&1
   conda activate /opt/conda/conda-bld/<toolname_hash>/_build_env

## Testing the Docker image artifact
docker run -it <image_id_from_docker_images_command>
```

## Prerequisites

1. Make a fork of the [bioconda-recipes](https://github.com/bioconda/bioconda-recipes/) GitHub repository, and clone this to our local machine [^3].

2. Install on our local machine the following software:

   - `conda` itself
     - I used to use [miniconda](https://docs.anaconda.com/miniconda/miniconda-other-installer-links/), but now switching to [miniforge](https://conda-forge.org/miniforge/) due to licensing issues [^4]
   - Bioconda configured as a source channel (see [bioconda documentation](https://bioconda.github.io/#usage))
   - The following conda packages:

     - `conda-utils`
     - `bioconda-build`
     - `greyskull` (optional: for Python software on pypi or R packages on CRAN)

     I typically dump all of the above in a specific conda environment, generated with the following command:

     ```bash
     conda create -n bioconda-build -c conda-forge -c bioconda conda-build bioconda-utils greyskull
     conda activate bioconda-build
     ```

   - `docker` (optional: for local build testing)

## Adding a new tool or package to Bioconda

### Preparation

0. Ask: _is my software already on Bioconda?_

   - Search the Bioconda website [https://bioconda.github.io/](https://bioconda.github.io/) to make sure some kind soul hasn't already done this.
   - Also double check the software doesn't already exist on another conda channel on [Anaconda](https://anaconda.org/).

1. Ask: _Is the software right for Bioconda?_

   - Bioconda is for bioinformatics software.
   - If the tool is a more generic tool or for a different domain, we may want to consider adding it to conda-forge [^2].
   - One common caveat to this is R packages - if our biology-related package is on CRAN ([https://cran.r-project.org/](https://cran.r-project.org/)), it should go on conda-forge, if it's on Bioconductor ([https://www.bioconductor.org/](https://www.bioconductor.org/)) it should go on Bioconda (if it's not already there).

2. Check: _Does the software have a compatible license?_ (i.e., allows redistribution)

3. Check: _Does the software have a stable release?_

   - I.e., an unmodifiable file (tarball or zip) and stable URL that that specific version can be always be downloaded from.
   - An example is a GitHub release (e.g. for a [Kraken2 release](https://github.com/DerrickWood/kraken2/releases/tag/v2.1.3), we use the link of the 'Source code (tar.gz)', i.e.,: [https://github.com/DerrickWood/kraken2/archive/refs/tags/v2.1.3.tar.gz](https://github.com/DerrickWood/kraken2/archive/refs/tags/v2.1.3.tar.gz)).
   - Using GitHub 'tags' are sort of OK.
   - Using specific commits (i.e., no versioned release tarballs) are strongly frowned upon.

If we are all good with the above, we can put our tool or package on Bioconda.

### Writing the recipe

A Bioconda recipe at a minimum can consist of a single file called `meta.yaml`.
This is often sufficient for PyPi Python and many R packages (respectively).

1. Create a new git branch for the tool we wish to add within the forked and cloned `bioconda-recipes` repository:

   ```bash
   git switch -c add-<toolname>
   ```

2. Make a `meta.yaml` file within the created directory, with one of two methods:

   1. If the tool is a Python package on pypi or a R package on CRAN, we can use `grayskull` to generate this for us.

      ```bash
      cd recipes/
      greyskull <pypi/cran> <toolname>
      ```

   2. In all other cases, make a new directory in the `recipes/` directory, named after the software we wish to add.

      ```bash
      mkdir recipes/<toolname>
      ```

      The name of the software must be formatted in all lower case, and with only letters, numbers, and hyphens.

      If our package is an R package, we should prefix the name with `r-`.

      ⚠ Make sure a tool with the same name doesn't exist!
      If it does - consider adding a suffix.
      For example, [`-mg` to indicate software for metagenomics](https://github.com/bioconda/bioconda-recipes/blob/master/recipes/metawrap-mg/meta.yaml), or [`-lite` for a version of a recipe that doesn't include preinstalled databases](https://github.com/bioconda/bioconda-recipes/blob/master/recipes/antismash-lite/meta.yaml).

      Then, create an empty text file called `meta.yaml` in the new directory.

      ```bash
      touch recipes/<toolname>/meta.yaml
      ```

3. Add the following sections in the `meta.yaml` file (or double check if already made with `grayskull`).
   When in doubt, copy from other similar existing recipes already on Bioconda:

   - `package:`
     - Specify the name (same specifications as above) and version of the tool/package.
   - `source:`
     - Specify the URL to the source code tarball or zip file for conda to download.
     - The e.g. `sha265` hash string of the file for download verification.
   - `build:`
     - Specify the build number (for new packages or new software version, always `0`).
     - Possibly the architecture (e.g. `noarch` for Python packages).
     - A `run_exports` subpackage pinning.
   - `requirements:`
     - Specify a list of the various dependencies of the software needs during various sections of the build process, i.e., `host`, `build`, and `run`.
     - Should have a minimum versions, and ideally a with [`>=` notation](https://docs.conda.io/projects/conda-build/en/latest/resources/package-spec.html#id3).
   - `test:`
     - One or more (e.g. if multiple CLI tools or scripts exist under the package) commands to test the software installed correctly.
     - Typically simply running the tool with `--help` or `--version` is sufficient, but must have a `0` exit code to indicate success.
     - If `--help` ends with a non-`0` code, we can try `grep`ing for a string in the help message.
   - `about:`
     - URL of such as source code repository or documentation home page.
     - License type [^5].
     - Corresponding license file name as in the tarball.
     - A short one-sentence summary and/or long-form description of the software.
   - `extras:`
     - other metadata information such as the DOI identifier of any associated publication the software may have.
     - Other identifiers of the software.

   ![A relatively simple example conda recipe example for Centrifuge, based on the descriptions above]({% link assets/images/2024-08-14-bioconda-guide/bioconda-guide-centrifugemeta.png %})
   _A relatively simple example conda recipe example for Centrifuge, based on the descriptions above._

4. Lint our `meta.yaml` for any errors pertaining to Bioconda [linting guidelines](https://bioconda.github.io/contributor/linting.html) (make sure we're in the root of the repository!).

   ```bash
   bioconda-utils lint recipes/ --packages <toolname>
   ```

   If there are any errors, I recommend fixing them before proceeding, as getting the same errors during the Bioconda GitHub CI takes a long time (as we'll see later).
   In particular, the `missing_run_exports` is a new linting check that has been added recently, that many people are not aware of.
   To solve this one, look at recently merged recipes, as the PR template describes how to set this under 'Instructions for avoiding API, ABI, and CLI breakage issues', such as on this [][`pango-collapse` PR](https://github.com/bioconda/bioconda-recipes/pull/50377).

### Writing a build script (optional)

For some tools, we may also need to create a `build.sh` script [^6] in the same directory alongside the `meta.yaml` file.

This is simply a shell script that is run during the build process after cloning of the source code.
The commands executed in this script are run in a specific build environment.

The purpose of this script varies, so I can't give a precise definition or explicit steps for writing one, but in my experience it is most often used in cases of:

- Tools that need to be compiled from source code (e.g. C++ tools and `make install`).
- Tools that are simply just an executable binary that needs to be linked or copied to the `bin/` of the eventual conda environment (e.g. Java `.jar` files).
- Tools that have additional 'auxiliary' or 'helper' scripts outside of (and in addition to) the main tool that also need to be copied to the `bin/` of the eventual conda environment.
- Patching files to allow them to run (often for simple patching with e.g. `sed`, more complex patching can use a git style `patch` file specified in the `meta.yaml`).

  - Patching can be stuff like adding a `shebang` at the top of a file
  - Replacing hardcode paths or variables in `make` files etc.

- Tools that may require other files to be copied to other directories in the conda environment (e.g. databases).

![A relatively simple example build.sh script example for Centrifuge, based on the descriptions above. Here it includes both `make install` compilation examples with Bioconda C++ environment variables and copying of the additional auxiliary scripts to the `bin/` directory.]({% link assets/images/2024-08-14-bioconda-guide/bioconda-guide-centrifugebuild.png %})

_A relatively simple example `build.sh` script example for Centrifuge, based on the descriptions above. Here it includes both `make install` compilation examples with Bioconda C++ environment variables and copying of the additional auxiliary scripts to the `bin/` directory._

However, as always, check other tools/packages for examples.

Examples of small `build.sh` scripts from the four examples above:

- [kallisto](https://github.com/bioconda/bioconda-recipes/blob/23fe8cc0729ff70883819a8d2b2fdfc4d1da1443/recipes/kallisto/build.sh) (make install).
- [MALT](https://github.com/bioconda/bioconda-recipes/blob/23fe8cc0729ff70883819a8d2b2fdfc4d1da1443/recipes/malt/build.sh) (java jar file).
- [metabinner](https://github.com/bioconda/bioconda-recipes/blob/23fe8cc0729ff70883819a8d2b2fdfc4d1da1443/recipes/metabinner/build.sh) (auxiliary scripts).
- [phynder](https://github.com/bioconda/bioconda-recipes/blob/23fe8cc0729ff70883819a8d2b2fdfc4d1da1443/recipes/phynder/build.sh) (patching).
- [grid](https://github.com/bioconda/bioconda-recipes/blob/23fe8cc0729ff70883819a8d2b2fdfc4d1da1443/recipes/grid/build.sh) (database files).

To provide further guidance based on my experience:

The `$PREFIX` variable corresponds to the the root of the conda environment that eventually gets made on a users system when they install the conda package.
You can explore our own conda environments to see what the `$PREFIX` looks like by running `conda env list` to see all of our own conda environments, and changing into the one of the directory listed in there.
They often will look very similar to Unix root directories, with folders such as `etc/`, `bin/`, `lib/`, `share/`, etc.
for example, if we have an executable or scripts that need to go into `bin/`, we must copy this into `$PREFIX/bin`.
For some tools we may have to copy other files into other directories, such as databases [^7], but this is less common.

Another tricky thing is compiling of C++ code, which can be a bit of a pain.
For reasons [^8], we need to use specific variables that point to the non-standard (it seems) places that conda stores its libraries and headers.
These are described [here](https://bioconda.github.io/contributor/guidelines.html#c-c), and in particular for [zlib](https://bioconda.github.io/contributor/troubleshooting.html#zlib-errors).
You often will need to patch the `make` files and other compilation related scripts to use these variables, and also to use the `--prefix=$PREFIX` flag when running `make install`.

For all of the above, regardless of language, I recommend looking at the the [contributor guidelines](https://bioconda.github.io/contributor/guidelines.html).

### Build testing

Once we think we've got our `meta.yaml` and `build.sh` (if needed) files ready, we can now try to see if this works.

We have two options here, either:

- Test it locally (less slow, but may not perfectly replicate the build).
- Open the pull request onto the main `bioconda-recipes` repository and see if it passes the tests there (slow).

If we want to just let the Bioconda CI do the testing, skip to the [next section](#opening-the-pull-request).

Otherwise, in our Bioconda-build conda environment, we can run one of two options (in both cases from the root directory of our `bioconda-recipes fork):

- The standard `conda build` command:

  ```bash
  conda build recipes/<toolname>
  ```

- The `bioconda-utils` command, which should better replicate the CI environment and also gives us the Biocontainer Docker version of our conda environment (but requires Docker, and is slower):

  ```bash
  bioconda-utils build --docker --mulled-test --packages <toolname>
  ```

In both cases, these commands will dump a huge amount of output to the terminal, and if it fails, we'll have to trawl through it to debug it.

I generally find the `bioconda-utils` method is slightly easier to debug because of the use of colours in the logging, with added benefit of making it easier to check the Biocontainer Docker image that gets created, but which method is up to personal preference.

### Debugging recipe building

If we have issues with the build process, we can try to debug it in the following ways.

1. Read carefully the very long log that gets generated from bottom to top.
   While tedious, often we can find the issue there, such as if the `test` command didn't work correctly.

2. Inspect the resulting environment itself.

   We can do this by changing into the `conda-bld/` directory of our Bioconda build conda environment (called here `bioconda-bld/`).

   Then we can try installing the environment but specifying that the conda _channel_ to take the software from is the directory we're in with `-c ./` (if we miss this, we'll install existing versions of the tool if they exist, or have an error that conda can't find the tool):

   ```bash
   cd /<path>/<to>/<conda-install>/envs/<toolname>/conda-bld/linux-64
   conda create -n <debugging-env-name> -c ./ <toolname_as_in_recipe>
   ```

3. Run the build process again but keeping all work directories, and investigate these (if the error message refers to one of those directories):

   ```bash
   conda build recipes/<toolname> --keep-old-work
   ```

4. If build with the `bioconda-utils` command, and this fails (and we've used the `--docker` command), and the error isn't obvious, we can deep dive into the Docker container that was created by the build process (i.e. recreating the 'exact' environment Bioconda itself will use), and follow the _exact_ steps the build process goes through:

   1. The error will produce a `COMMAND FAILED` message with a Docker command.
      It will look something like:

      ```bash
      docker run -t --net host --rm -v /tmp/tmp<randomletters>/build_script.bash:/opt/build_script.bash -v /<path>/<to>/<conda-install>/envs/<toolname>/conda-bld/:/opt/host-conda-bld -v /<path>/<to>/<recipes_local_clone>/recipes/<tool_name>:/opt/recipe -e LC_ADDRESS=en_GB.UTF-8 -e LC_NAME=en_GB.UTF-8 -e LC_MONETARY=en_GB.UTF-8 -e LC_PAPER=en_GB.UTF-8 -e LANG=en_GB.UTF-8 -e LC_IDENTIFICATION=en_GB.UTF-8 -e LC_TELEPHONE=en_GB.UTF-8 -e LC_MEASUREMENT=en_GB.UTF-8 -e LC_TIME=en_GB.UTF-8 -e LC_NUMERIC=en_GB.UTF-8 -e HOST_USER_ID=1000 quay.io/bioconda/bioconda-utils-build-env-cos7:2.11.1 bash
      ```

   2. Copy and paste that command, but replace `docker run -t` to `docker run -it`.
      This will open an 'interactive' session so we can play around within the container.

      ⚠ Basic tools such as `vim` are not in there! So depending on our preference, we will have to exit the Docker container to edit our `meta.yaml` or `build.sh` file each time, and re-run the command/ 3. Once in, there are two main locations of interest:

      - `/opt/recipe`: contains our entire recipe directory (e.g. with `meta.yaml` and `build.sh`).
      - `/opt/build_script.sh`: the commands that Bioconda actually run during the build process.

   3. To carry out the manual debugging, `cat build_script.sh` and run one-by-one each command in that file.
      Alternatively, copy and paste the entire contents, but DO NOT run the `set -eo pipefile` command at the top (this will exit the Docker container if something goes wrong).
   4. The first command I found commonly resulted in errors is:

      ```bash
      conda mambabuild -c file:///opt/host-conda-bld --override-channels --no-anaconda-upload -c conda-forge -c bioconda -c defaults -e /opt/host-conda-bld/conda_build_config_0_-e_conda_build_config.yaml -e /opt/host-conda-bld/conda_build_config_1_-e_bioconda_utils-conda_build_config.yaml /opt/recipe/meta.yaml 2>&1
      ```

      This is the primary command that runs the entire building of the recipe.

   5. If step 6 fails during the `build.sh` steps (as indicated by the console log), we will want to manually execute the `build.sh` script.
      Before we do this, we must make sure to activate the build environment (the one within which we would e.g. compile a `c++` tool):

      ```bash
      conda activate /opt/conda/conda-bld/<packagename_hash>/_build_env
      ```

      When running the commands in the `build.sh`, we may also need to manually `export` the `PREFIX` bash environment variable when dealing with `build.sh`.
      To find this, look for the long horrible `_test_env_placehold_placehold_placehold_placehold_p<...>` directory that gets reported in the log during our initial building run.

   6. To check the actual build output files, i.e., the working directory that `build.sh` is executed in:

      ```bash
      /opt/conda/conda-bld/<tool/package-name>_<random-numbers>/work
      ```

If none of this solves your issue, we can ask for help from the Bioconda community by opening a Pull Request and leaving a comment pinging @bioconda/\<team\> (replacing '\<team\>' with the respective one from the list that should come up).

### Opening the Pull Request

Once we're happy with our recipe, we can open a pull request on the main `bioconda-recipes` repository on GitHub.

We can do this (if you're not too familiar with GitHub), by:

1. On your local repo, `git add`ing the files you've added, commit, and push.
2. Go to the main `bioconda-recipes` repository on GitHub.
3. Switch to the Pull Requests tab.
4. Press the green 'New Pull Request' button.
5. In the top bar use the dropdowns to select our fork and branch (which should then be going _into_ `bioconda/bioconda-recipes` and the `master` branch).
6. Make sure the title of the pull request is follows the recommendations, typically just `Add <tool/package>` or `Update <tool/package>`.
7. Once we open the pull request, the Bioconda CI will run.

We can see the overall status of the checks near the bottom of the page below the 'Review required' message.
For most builds this currently happens away from GitHub on Microsoft Azure, and can take a while (sometimes up to 1 hour!) to complete (so be patient).

To get more information on the status of the CI test, and also logs, press 'details' next to one of the checks (it generally doesn't matter which one), then press the 'View more details on Azure Pipelines' link on the resulting page.

On the Azure website we should see a series of 'stages', that run in order. The tests that are run in these stages are:

1. `lint`: checks we've not missed anything (e.g. the LICENSE).
2. `test_linux`: that the recipe builds on a Linux system (i.e., doesn't error and the test command completes).
3. `test_osx`: that the recipe builds on a macOS system (i.e., doesn't error and the test command completes).

A given stage has a completed (green tick), running (blue spinny icon), or failed (red cross) status.
If we click on any of the stages, we should see log files that similar or identical what we would do if we were [building locally](#debugging-recipe-building) (see that section for debugging advice, if we skipped local building).

![Screenshot of bottom of a GitHub PR with the checks list displayed with blue 'Details' links next to each test.]({% link assets/images/2024-08-14-bioconda-guide/bioconda-guide-githubchecks.png %})

_Screenshot of bottom of a GitHub PR with the checks list displayed with blue 'Details' links next to each test_

![Screenshot of the Microsoft Azure interface with the three (successful) Bioconda CI stages.]({% link assets/images/2024-08-14-bioconda-guide/bioconda-guide-azurechecks.png %})

_Screenshot of the Microsoft Azure interface with the three (successful) Bioconda CI stages._

If the CI passes, then back on GitHub we can leave a comment in our PR saying '@BiocondaBot please add label'.
This will add a label to our PR indicating a Bioconda team member can review our recipe to ensure it matches the guidelines.
If they give an approval, they or we can merge our PR into the main `bioconda-recipes` repository!
We're now officially a Bioconda recipe maintainer 🎉.

Once the recipe is merged in, we can normally install the official version of our tool/package with conda within a few minutes.
At the same time, on merging, the auto-generated Docker Biocontainer gets uploaded to the Biocontainers `quay.io` repository.
For the Singularity version of the Docker container, this can take up to 24h before it's visible on the [Galaxy project's 'depot'](https://depot.galaxyproject.org/singularity/).

### Test driving the docker Biocontainer

If we used the `bioconda-utils` command to build our recipe, we can also test the Biocontainer Docker image that was generated from the conda environment that was built.

If we did a local build, the Docker image is already on our own machine.

If we let the automated Bioconda CI do the testing on Azure, we can leave a comment with '@BiocondaBot please fetch artifacts' and this will generate a comment on the PR with two tables.
We can download the `LinuxArtifacts.zip` file from the top table (`Package(s) built are ready...`), unzip it and then run the command given in `Docker image(s) built` table to load the container.

Then for both local or GitHub build cases, we can just access the created Docker container by finding it in the the output of `docker images`.
The image will be named something like `quay.io/biocontainers/<toolname>`, and I typically run the following command to access container and run additional test commands or experiments within the container.

```bash
docker run -it <image_id_from_docker_images_command>
```

This should dump us within a shell in the container so we can test commands etc. as we would with any other Docker container.

## Updating an existing tool or package recipe on Bioconda

If we're updating or fixing an existing recipe, the process is similar to adding a new tool, but with a few differences.

Note that if we use GitHub releases for our tool/package, Bioconda tries to _automatically_ update Bioconda recipes for us, so we may not need to do this manually.
Of course, this works if there are no changes to the dependencies or tests that can cause the tests and thus the recipe building to fail.

Otherwise, to manually update or fix a recipe:

1. Make sure our `bioconda-recipes` fork is up to date with the main.
2. Make a new branch for the update.
3. Edit the `meta.yaml`, `build.sh` files of the recipe with our changes.
4. Update the build number:
   - If it is simply _fixing_ a recipe with no version change of the tool, bump the `build_number` by `+1`.
   - If this is a new version of the tool, set the `build_number` to `0`.
5. Add all files, commit and push to our fork.
6. Open the PR on `bioconda-recipes`, wait for the CI to to complete successfully, and tag for review with '@BiocondaBot please add label' as above.

## Conclusion

This guide hopefully has given you enough pointers on the steps required to make a recipe and submit your tool/package to Bioconda, and also where to look for the most important places for debugging build failures when they occur.

As with all bioinformatics and software development in general, things rarely just 'work' straight out of the box.
My three biggest points of advice:

- Always copy and paste from other similar tools or packages on the Bioconda recipes repository.
- Take the time to read through the whole log messages (sometimes you can find critical clues hidden amongst the verbose information).
- Take the time to go step by step trying to follow exactly what Bioconda does during it's own building on Azure with local building.

I found by taking the time, I very quickly learnt common issues and how to solve them.

Worst comes to worst, you can always ask the very friendly Bioconda team on the [Bioconda gitter/matrix channel](https://gitter.im/bioconda/Lobby).

## Footnotes

[^2]: Note that conda-forge has a different system for adding packages!
[^3]: You can do a shallow clone `git clone --depth 1`, to make the size of the cloned repo smaller on your machine. Thanks to @Wytamma for the tip!
[^4]: Various Bioconda documentation pages say we should use `mamba`, but recent versions of conda include `lib-mamba` by default, so generally we can use standard `conda`. But if you're having problems with things being very slow, try switching to `mamba`.
[^5]: Possibly from a fixed list, and how to format these, I don't know... I just copy and paste from other recipes.
[^6]: I've noticed in a few more recent recipes that these commands can go within the `meta.yaml` itself [in an entry](https://docs.conda.io/projects/conda-build/en/stable/resources/define-metadata.html#script) called `script:` under `build:`, but I guess this only works for very simple commands...
[^7]: Even though I absolutely HATE this, as often it leads to gigantic multi-gigabyte conda environments which we can't use on small CI runners. Give me the choice where to store my databases already! Don't force me to place them in a specific place /rant.
[^8]: That I've never found a good explanation or documentation for.
