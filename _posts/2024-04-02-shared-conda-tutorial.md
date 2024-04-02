---
layout: post
title: The ideal setup for a multi-user conda installation
tags: conda bash systems-administration
contributors:
- boulund
- pmenzel
- hexylena
---

[Conda](https://docs.conda.io/projects/conda/en/stable/) and [Bioconda](https://bioconda.github.io/) have become crucial tools in most bioinformatician's toolkit. It is often used to install applications and create reproducible environments on their system or a compute cluster. 

On multi-user systems (e.g. shared Linux servers), multiple users can share  the same conda installation and the environments thererin. This is a good idea and usually works well when only already existing environments are re-used, but can become tricky when users also want to create environments (using `conda create`) into the shared conda installation. On a standard Linux system, this often results in permission problems when (re-)downloading packages and overwriting files that were created by others.

Here we describe a setup with a shared (read-only) conda installation, with re-usable shared environments, and private per-user environments.


## Tutorial

### Creating the shared conda installation


First, create a shared conda installation folder that is read-only for all regular users. Shared conda environments therein, which are available to all users, must be created by the sysadmin (or with a user account with the correct privileges for the conda folder). 

In this tutorial we'll use `/apps/conda` as the path, but please choose something appropriate for your system.

We install conda by downloading and running the [Miniconda installer](https://repo.anaconda.com/miniconda/), but feel free to use the [full Anaconda installer](https://repo.anaconda.com/archive/) if that is your preference. We also set up folder permissions and an initial conda config, which includes the recommended [bioconda](https://bioconda.github.io/) and [conda-forge](https://conda-forge.org/) channels.

```bash
# Create shared conda folder
CONDA_PATH="/apps/conda"
sudo mkdir -pv "${CONDA_PATH}"
sudo chmod 755 "${CONDA_PATH}"

# Download Miniconda installer
CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
wget ${CONDA_URL} --output-document=/tmp/conda_installer.sh

# Install Miniconda
# -b          run install in batch mode (without manual intervention),
#             it is expected the license terms (if any) are agreed upon
# -p PREFIX   install prefix, defaults to $PREFIX, must not contain spaces.
sudo /tmp/conda_installer.sh -b -p "${CONDA_PATH}"

# Set default conda settings for all users
# (these will show up in $CONDA_PATH/.condarc)
sudo "${CONDA_PATH}"/bin/conda config --system --set channel_priority strict
sudo "${CONDA_PATH}"/bin/conda config --system --add channels defaults
sudo "${CONDA_PATH}"/bin/conda config --system --add channels bioconda
sudo "${CONDA_PATH}"/bin/conda config --system --add channels conda-forge
```

Users can override default conda settings in their own `$HOME/.condarc` configuration files.

### Using the shared conda installation
Users can activate the shared conda base environment by running
```bash
/apps/conda/bin/conda init
```
to permanently initialize it for their user (this configures the user's `$HOME/.bashrc` to activate the shared conda base env upon login).

If users prefer not to automatically activate conda upon login, users can also opt to manually run 
```bash
source /apps/conda/bin/activate [optional_conda_env_name]
```
to temporarily activate it each time they want to use the shared conda installation (and use conda as usual for the rest of this bash session).


### User-specific conda environments
Users can create their own custom conda environments like usual, e.g. `conda create -n myenv ...`, but since users cannot write into the shared conda installation folder conda will automatically put the users' own environments in `$HOME/.conda/envs/`. Note that environments created by users this way are unavailable to other users on the system, unless they opened up the permissions of their home folder.


## Other Tips & Tricks

### Activating Conda Dynamically

If you do not like having conda always active due to shell startup speed impact, or having to remember to `source ...` it, you can do like @hexylena does and source it dynamically on first invocation.

By adding this function to your shell initialisation (`$HOME/.bashrc`), when you run a conda command like `conda activate x` it will first delete the function definition before sourcing the conda hook and running your desired conda command:

```bash
function conda {
        unset R_LIBS_USER
        unset -f conda

        # shellcheck disable=SC1090
        eval "$(/home/user/arbeit/deps/miniconda3/bin/conda shell.zsh hook)"
        conda "${@}"
}
```

The above function is directly from her `~/.zshrc` but should work similarly under Bash with `zsh` replaced with `bash`.
