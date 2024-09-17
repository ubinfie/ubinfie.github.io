---
layout: post
title: Debugging a Bioconda build - a reference guide
date: 2024-08-16 12:00:00
author: "James A. Fellows Yates"
tags:
  - development
  - conda
  - bioconda
  - software
contributors:
  - jfy133
reviewers:
  - samuell
  - wytamma
  - pmenzel
---

In the third part of this three part guide, we will go through an (opinionated) approach to debug a Bioconda recipe or build.

- _For part one of this guide, see [adding a new tool or package to Bioconda]({% post_url 2024-08-16-adding-to-bioconda-quickguide %})._
- _For part two of this guide, see [updating a package on Bioconda]({% post_url 2024-08-16-updating-bioconda-recipe-quickguide %})._

The [conda package manager](https://docs.conda.io/en/latest/) combined with the [Bioconda](https://bioconda.github.io/) repository has become a _de facto_ gold-standard way for distributing bioinformatics software ({% cite Gruening2018 %}).
The associated [Biocontainer](https://biocontainers.pro/) project serves to provide complementary Docker and Singularity containers from the same conda ({% cite Da_Veiga_Leprevost2017 %}).

During the recipe creation (see [part one]({% post_url 2024-08-16-adding-to-bioconda-quickguide %})) or updating process (see [part two]({% post_url 2024-08-16-updating-bioconda-recipe-quickguide %})), we may encounter problems or issues.

This guide provides steps how to test both a standard `conda-build` build, but also a `bioconda-utils` process that occurs within a Docker container.

## Debugging the build with conda-build

If we have issues with the build process when using `conda-build`., we can try to debug it in the following ways.

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

## Debugging the build with bioconda-utils

If build with the `bioconda-utils` command, and this fails (and we've used the `--docker` command), and the error isn't obvious, we can deep dive into the Docker container that was created by the build process (i.e. recreating the 'exact' environment Bioconda itself will use), and follow the _exact_ steps the build process goes through:

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

## It's still not working!

If none of this solves your issue, we can ask for help from the Bioconda community by opening a Pull Request and leaving a comment pinging @bioconda/\<team\> (replacing '\<team\>' with the respective one from the list that should come up).

Once everything is solved, you can proceed with the last three sections in the [part one of this guide]({% post_url 2024-08-16-adding-to-bioconda-quickguide %}#opening-the-pull-request), to open the Pull Request and get a review.

## Conclusion

In this third and final part of this guide, we given you enough pointers on how debug a Bioconda recipe build both using `conda-build` and `bioconda-utils` approaches.

As with all bioinformatics and software development in general, things rarely just 'work' straight out of the box.
My three biggest points of advice:

- Always copy and paste from other similar tools or packages on the Bioconda recipes repository.
- Take the time to read through the whole log messages (sometimes you can find critical clues hidden amongst the verbose information).
- Take the time to go step by step trying to follow exactly what Bioconda is doing within `bioconda-utils`.

I found by taking the time, I very quickly learnt common issues and how to solve them.

Worst comes to worst, you can always ask the very friendly Bioconda team on the [Bioconda gitter/matrix channel](https://gitter.im/bioconda/Lobby).
