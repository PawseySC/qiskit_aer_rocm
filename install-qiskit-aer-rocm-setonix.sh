#!/bin/bash -l
# Source the environment script so that aer_ver, qiskit_ver, and source_dir get exported
script_dir="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
#
# Verify that aer_ver and qiskit_ver are set
if [[ -z "${aer_ver:-}" ]]; then
    echo "Error: aer_ver is not set. Exiting." >&2
    exit 1
fi

if [[ -z "${qiskit_ver:-}" ]]; then
    echo "Error: qiskit_ver is not set. Exiting." >&2
    exit 1
fi

if [[ -z "${source_dir:-}" ]]; then
    echo "Error: source_dir is not set. Exiting." >&2
    exit 1
fi

if [[ -z "${venv_dir:-}" ]]; then
    echo "Error: venv_dir is not set. Exiting." >&2
    exit 1
fi

source $venv_dir/bin/activate

mkdir -p "$source_dir"

# Clone Qiskit-Aer at the requested tag/branch
# I don't know why we were removing the clone_dir when it is undefined
clone_dir="$source_dir/qiskit-aer-${aer_ver}"
if [[ ! -d "$clone_dir" ]]; then
    echo "Cloning Qiskit-Aer source tree at branch/tag: $aer_ver"
    git clone -b "$aer_ver" "https://github.com/Qiskit/qiskit-aer" "$clone_dir"
fi
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
python -m pip install "qiskit==${qiskit_ver}"
python -m pip install -r requirements-dev.txt
python -m pip install pybind11


# --- Initialize and Patch Conan Version Restrictions ---
echo "==> Initializing native Conan cache configuration..."
conan config init
SETTINGS_FILE="$CONAN_USER_HOME/.conan/settings.yml"

if [ -f "$SETTINGS_FILE" ]; then
    echo "Injecting AMD Clang 18 compatibility profiles into settings.yml..."
    sed -i 's/version: \["3.3",/version: \["18", "3.3",/' "$SETTINGS_FILE"
else
    echo "Fatal Error: Conan profile infrastructure template was not generated."
    exit 1
fi


# Locate gcc toolchain for hipcc
REAL_GCC=$(which gcc)
REAL_GXX=$(which g++)
REAL_HIPCC=$(which hipcc)
ROCM_PATH=${ROCM_PREFIX:-"/software/setonix/rocm/6.3.0"}

gcc_path="$(realpath "$REAL_GCC")"
toolchain_path="$(dirname "$(dirname "$gcc_path")")"

# Set standard native compiler paths (Wrapper omitted)
export CC="$REAL_GCC"
export CXX="$REAL_GXX"

# Disable redundant internal driver version evaluations
export CONAN_DISABLE_CHECK_COMPILER=ON


# --- Build and Install the Target Architecture Wheel Package ---
# Note: Problems found when using setup.py I don't know why
echo "==> Triggering production CMake wheel build generation step..."
export CMAKE_ARGS="-DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_COMPILER=$REAL_HIPCC \
  -DCMAKE_C_COMPILER=$REAL_GCC \
  -DAER_THRUST_BACKEND=ROCM \
  -DAER_ROCM_ARCH=gfx90a \
  -DAER_MPI=True \
  -DAER_DISABLE_GDR=True \
  -DCONAN_DISABLE_CHECK_COMPILER=ON \
  -DNOTHRUST_ROCM_DETECTION=OFF \
  -DCMAKE_PREFIX_PATH=$ROCM_PATH \
  -DCMAKE_CXX_FLAGS=--gcc-toolchain=$toolchain_path \
  -DCONAN_SYSTEM_INCLUDES=ON"

# Build target binary wheel package using modern pip standard wheels
python -m pip wheel . --no-deps --no-build-isolation -w dist/

echo "Deploying completed architectural wheel package..."
python -m pip install dist/*.whl

# Revert terminal back to baseline script directory context
cd "$script_dir"
echo "[SUCCESS] Build, deployment, and library activation phase complete."