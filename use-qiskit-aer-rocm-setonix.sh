#!/bin/bash

# If QISKIT_VER is set, use it; otherwise default to 2.0.2
export qiskit_ver="${QISKIT_VER:-2.0.2}"
# If AER_VER is set, use it; otherwise default to 0.16.1
export aer_ver="${AER_VER:-0.17}"
# If VENV_DIR is set, use it; otherwise default to "$MYSCRATCH/qiskit-aer-venv-${qiskit_ver}"
venv_dir="${VENV_DIR:-$MYSCRATCH/qiskit-aer-venv-${qiskit_ver}}"

# Required to build qiskit-aer
py_ver="3.11.6"
pip_ver="23.1.2-py3.11.6"
st_ver="68.0.0-py3.11.6"
blas_ver="0.3.24"
rocm_ver="5.7.1"

# Python modules to use instead of installing from pip
numpy_ver="1.26.1"
scikit_ver="1.3.2"
scipy_ver="1.11.3"

# Edits passed this point shouldn't be necesseary.
# -------------------------------------------------------

export script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
export source_dir="$script_dir/qiskit-rocm-src"

# Load qiskit-aer dependencies
module load "python/$py_ver"
module load "py-pip/$pip_ver"
module load "py-setuptools/$st_ver"
module load "openblas/$blas_ver"
module load "rocm/$rocm_ver"
module load "craype-accel-amd-gfx90a"
module load "gcc"         # so that hipcc can find the gcc toolchain

# Load python modules
module load "py-numpy/$numpy_ver"
module load "py-scikit-learn/$scikit_ver"
module load "py-scipy/$scipy_ver"


# Create or reuse $venv_dir
if [[ ! -d "$venv_dir" ]]; then
    echo "Creating new virtual environment at: $venv_dir"
    python -m venv "$venv_dir"
fi
echo "Activating virtual environment: $venv_dir"
source "$venv_dir/bin/activate"

# Check wether qiskit-aer is installed, if it isn't, install it
current_ver=$(python -m pip show qiskit-aer 2>/dev/null | awk '/^Version:/{print $2}')

if [[ -n "$current_ver" ]]; then
  short_cur=${current_ver%%[+!~-]*}
  if [[ "$short_cur" != "$aer_ver" ]]; then
    echo "Found qiskit-aer $current_ver..."
  fi
else
  echo "qiskit-aer not installed — building."
  source "$script_dir/install-qiskit-aer-rocm-setonix.sh"
fi
