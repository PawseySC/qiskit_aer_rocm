#!/bin/bash -l
# Source the environment script so that aer_ver, qiskit_ver, and source_dir get exported
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
#
# Verify that aer_ver and qiskit_ver are set
if [[ -z "${aer_ver:-}" ]]; then
    echo "Error: aer_ver is not set. Exiting." >&2
    exit 1
fi

if [[ -z "${qiskit_terra_ver:-}" ]]; then
    echo "Error: qiskit_ver is not set. Exiting." >&2
    exit 1
fi

source $venv_dir/bin/activate

mkdir -p "$source_dir"

# Clone Qiskit-Aer at the requested tag/branch
clone_dir="$source_dir/qiskit-aer-${aer_ver}"
git clone -b "$aer_ver" "https://github.com/Qiskit/qiskit-aer" "$clone_dir"
cd "$clone_dir"

# set an isolated conan cache outside of $HOME
export CONAN_USER_HOME="$clone_dir/.conan_cache"

# set the pip cache to avoid file quota issues on $MYSOFTWARE
export PIP_CACHE_DIR="$source_dir/.pip_cache"
mkdir -p "$PIP_CACHE_DIR"

# Clean previous build artifacts
rm -rf _skbuild "$CONAN_USER_HOME"

# Update/Install build tools
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools wheel
python -m pip install --upgrade cmake

# Install Aer's development requirements in the venv
python -m pip install "qiskit-terra==${qiskit_terra_ver}"
python -m pip install -r requirements-dev.txt
python -m pip install pybind11

# Locate gcc toolchain for hipcc
gcc_path="$(realpath "$(command -v gcc)")"
toolchain_path="$(dirname "$(dirname "$gcc_path")")"

# Build a ROCm‐compatible wheel
python setup.py bdist_wheel -- \
  -DCMAKE_CXX_COMPILER=hipcc \
  -DCMAKE_CXX_FLAGS="--gcc-toolchain=$toolchain_path" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -DAER_MPI=True \
  -DAER_THRUST_BACKEND=ROCM \
  -DAER_ROCM_ARCH=gfx90a \
  -DAER_DISABLE_GDR=True \
  -DPython_EXECUTABLE=$(which python)

# Install the newly built wheel
python -m pip install dist/*.whl

# Return to the original script directory
cd "$script_dir"
