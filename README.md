# Qiskit-Aer ROCm Build (Setonix)

Scripts to build a ROCm-enabled Qiskit-Aer wheel and install it in a Python 3.11 virtual environment on the Pawsey Setonix GPU cluster.

## Quick Start

```bash
# Clone repo (if not already)
git clone https://github.com/PawseySC/qiskit_aer_rocm.git
cd  qiskit_aer_rocm

# Submit build job – defaults to QISKIT_AER_VER=0.16.1, venv=$MYSCRATCH/qiskit-aer-venv-0.16.1
sbatch -N1 --gpus=1 -p gpu-dev --account=${PAWSEY_PROJECT}-gpu install-qiskit-source-rocm-setonix
````

The job:

1. Loads the required Setonix modules.
2. Creates (or re-uses) the venv.
3. Clones Qiskit-Aer, builds a ROCm wheel, and installs it in the venv.


## Custom Build

Override defaults by exporting variables before the `sbatch`:

```bash
export QISKIT_AER_VER="0.17.0"           # default: 0.16.1
export QISKIT_VER="2.0.2"                # metapackage version (rarely needed)
export VENV_DIR="$PWD/my-aer-venv"       # default: $MYSCRATCH/qiskit-aer-venv-$QISKIT_AER_VER

sbatch --export=ALL -N 1 --gpus=1 -p gpu-dev --account=${PAWSEY_PROJECT}-gpu install-qiskit-source-rocm-setonix
```

## Using the Environment

If you used custom variables, export the same ones again:

```bash
export QISKIT_AER_VER="0.17.0"
export VENV_DIR="$PWD/my-aer-venv"
````

Then activate the env:

```bash
 source /path/to/repo/use-qiskit-aer-rocm-setonix.sh
```

`use-qiskit-aer-rocm-setonix.sh` is idempotent:

* It loads the modules if they’re not loaded.
* It activates the venv if it exists, otherwise it tells you to run the install job.


## Troubleshooting

If the build fails, first clean up the build and environment directories before re-trying:

```bash
rm -rf qiskit-rocm-src/      # cloned source + Conan cache
rm -rf qiskit-aer-venv*      # default virtual env(s)
# or: rm -rf "$VENV_DIR"
```
