# Qiskit-Aer ROCm Build (Setonix)

Scripts to build a ROCm-enabled Qiskit-Aer wheel and install it in a Python 3.11 virtual environment on the Pawsey Setonix GPU cluster.

> **Tip:** For runtime guidance on GPU acceleration see [GPU Simulation](https://qiskit.github.io/qiskit-aer/tutorials/1_aersimulator.html#GPU-Simulation). The steps there mention CUDA/NVIDIA, but they apply equally to this ROCm/AMD build.

## Quick Start

1. Clone:

```bash
git clone https://github.com/PawseySC/qiskit_aer_rocm.git
cd  qiskit_aer_rocm
```
2. Submit the build job:

```bash
sbatch -N1 --gpus=1 -p gpu-dev --account=${PAWSEY_PROJECT}-gpu \
bash install-qiskit-source-rocm-setonix.sh
```

What the job does:

1. Loads the required Setonix modules.
2. If no virtual environment is already active, it creates (or re-uses) the target venv.
3. Clones Qiskit-Aer, builds a ROCm wheel, and installs it into that venv.


## Custom Build

Override defaults by exporting variables before the `sbatch` call:

```bash
export AER_VER="0.16.0"         # default: 0.16.1
export QISKIT_TERRA_VER="0.45.0"       # default: 0.46.0
export VENV_DIR="$PWD/my-aer-venv"     # default: $MYSCRATCH/qiskit-aer-venv-$AER_VER

sbatch --export=ALL -N1 --gpus=1 -p gpu-dev \
--account=${PAWSEY_PROJECT}-gpu bash install-qiskit-source-rocm-setonix.sh
```

## Using the Environment

If you build with custom variables, re-export them in any new session:

```bash
export AER_VER="0.17.0"
export VENV_DIR="$PWD/my-aer-venv"
```

Activate (or re-activate) the environment:

```bash
source /path/to/repo/use-qiskit-aer-rocm-setonix.sh
```

`use-qiskit-aer-rocm-setonix.sh` is idempotent:

* It loads the required modules if they are not already loaded.
* If a venv is already active (`$VIRTUAL_ENV`), it keeps using it.
* Otherwise it activates the configured venv (creating it if needed) or reminds you to run the install job.


## Troubleshooting

If a build fails, clear the workspace and venv before retrying:

```bash
rm -rf qiskit-rocm-src/      # cloned source + Conan cache
rm -rf qiskit-aer-venv*      # default virtual env(s)
# or: rm -rf "$VENV_DIR"     # if you used a custom path
```
