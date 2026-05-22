#!/bin/bash
# ---------------------------------------------------------------------------
# WRF v4.7.1 clean build — Lengau (Intel oneAPI 2021.3 or GNU gcc+MPICH)
#
# Environment:
#   INSTALL_DIR          install root (default /home/apps/chpc/earth/WRF-4.7.1)
#   TOOLCHAIN            intel | gcc   (default intel)
#   WRF_HYDRO            0 | 1         (default 0)
#   WRF_CONFIG_OPTION    configure menu choice (intel default 66 HSW/BDW, gcc 34)
#   WRF_RUN_CLEAN        0 skips ./clean -a (required if phys/physics_mmm present)
#   MAX_PASSES           compile passes at -j 1 (default 8)
# ---------------------------------------------------------------------------
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/home/apps/chpc/earth/WRF-4.7.1}"
BUILD_DIR="${INSTALL_DIR}/build"
WRF_DIR="${BUILD_DIR}/WRF"
MODULE_DIR="${MODULE_DIR:-/apps/chpc/scripts/modules/earth}"
TOOLCHAIN="${TOOLCHAIN:-intel}"
ENABLE_HYDRO="${WRF_HYDRO:-0}"
WRF_NEST_OPTION="${WRF_NEST_OPTION:-1}"
WRF_CASE="${WRF_CASE:-em_real}"
MAX_PASSES="${MAX_PASSES:-8}"

if [[ "${TOOLCHAIN}" == "intel" ]]; then
    ONEAPI="${ONEAPI:-/home/apps/chpc/compmech/compilers/intel_2021.3/oneapi}"
    NETCDF_MODULE="${NETCDF_MODULE:-chpc/earth/netcdf/4.9.2-intel2021.3}"
    WRF_CONFIG_OPTION="${WRF_CONFIG_OPTION:-66}"
    MODULE_NAME="${MODULE_NAME:-wrf-lengau}"
    if [[ "${ENABLE_HYDRO}" == "1" && "${MODULE_NAME}" != *hydro* ]]; then
        MODULE_NAME="${MODULE_NAME}-hydro"
    fi
else
    NETCDF_MODULE="${NETCDF_MODULE:-chpc/earth/netcdf/4.7.4/gcc-8.3.0}"
    WRF_CONFIG_OPTION="${WRF_CONFIG_OPTION:-34}"
    MODULE_NAME="${MODULE_NAME:-wrf-lengau-gcc}"
    if [[ "${ENABLE_HYDRO}" == "1" && "${MODULE_NAME}" != *hydro* ]]; then
        MODULE_NAME="${MODULE_NAME}-hydro"
    fi
fi

if [[ -z "${WRF_RUN_CLEAN:-}" ]]; then
    if [[ -d "${WRF_DIR}/phys/physics_mmm/.git" ]]; then
        WRF_RUN_CLEAN=0
    else
        WRF_RUN_CLEAN=1
    fi
fi

echo "=== WRF v4.7.1 clean build ==="
echo "INSTALL_DIR       = ${INSTALL_DIR}"
echo "TOOLCHAIN         = ${TOOLCHAIN}"
echo "WRF_HYDRO         = ${ENABLE_HYDRO}"
echo "WRF_CONFIG_OPTION = ${WRF_CONFIG_OPTION}"
echo "WRF_RUN_CLEAN     = ${WRF_RUN_CLEAN}"
echo "MAX_PASSES        = ${MAX_PASSES}"
echo

[[ -d "${WRF_DIR}" ]] || {
    echo "ERROR: ${WRF_DIR} missing. Run download_wrf_source.sh on DTN, then"
    echo "  checkout_wrf_externals_dtn.sh (needs phys/physics_mmm before compute build)."
    exit 1
}

module purge 2>/dev/null || true

if [[ "${TOOLCHAIN}" == "intel" ]]; then
    set +u
    source "${ONEAPI}/compiler/2021.3.0/env/vars.sh" >/dev/null
    source "${ONEAPI}/mpi/2021.3.0/env/vars.sh" >/dev/null
    set -u
    module load "${NETCDF_MODULE}"
    export NETCDF="${NETCDF_ROOT:?NETCDF_ROOT not set}"
    export HDF5="${NETCDF}/hdf5"
    export LD_LIBRARY_PATH="${HDF5}/lib:${NETCDF}/lib:${LD_LIBRARY_PATH:-}"
    export FC=ifort CC=icc CXX=icpc
else
    module load "${NETCDF_MODULE}"
    if ! command -v python3 &>/dev/null; then
        module load chpc/python/anaconda/3-2024.10.1 2>/dev/null || true
    fi
    export NETCDF="$(nc-config --prefix)"
    export FC=gfortran CC=gcc CXX=g++
fi

export WRF_ROOT="${INSTALL_DIR}"
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
export WRF_EM_CORE=1
export WRF_NMM_CORE=0

if [[ "${ENABLE_HYDRO}" == "1" ]]; then
    export WRF_HYDRO=1
    export HYDRO_D=1
else
    unset WRF_HYDRO HYDRO_D 2>/dev/null || true
fi

if [[ ! -d "${WRF_DIR}/phys/physics_mmm/.git" ]]; then
    echo "ERROR: phys/physics_mmm/.git missing."
    echo "On DTN run: INSTALL_DIR=${INSTALL_DIR} ./checkout_wrf_externals_dtn.sh"
    echo "Or copy from a tree that already has MMM physics:"
    echo "  rsync -a /home/apps/chpc/earth/WRF-4.7.1-gcc/build/WRF/phys/physics_mmm ${WRF_DIR}/phys/"
    exit 2
fi

cd "${WRF_DIR}"

if [[ "${WRF_RUN_CLEAN}" == "1" ]]; then
    echo "Running ./clean -a (will remove phys/physics_mmm — only if DTN checkout follows)..."
    ./clean -a >/dev/null 2>&1 || true
    rm -f compile*.log configure.log recover_pass*.log 2>/dev/null || true
else
    echo "Skipping ./clean -a — preserving phys/physics_mmm"
    rm -f configure.wrf configure.log compile*.log 2>/dev/null || true
fi

echo "Configuring (option ${WRF_CONFIG_OPTION}, hydro=${ENABLE_HYDRO})..."
printf '%s\n%s\n' "${WRF_CONFIG_OPTION}" "${WRF_NEST_OPTION}" | ./configure 2>&1 | tee configure.log
[[ -f configure.wrf ]] || { echo "ERROR: configure.wrf missing"; exit 2; }

if [[ "${TOOLCHAIN}" == "intel" ]]; then
    sed -i 's|^DM_FC[[:space:]]*=.*|DM_FC           = mpiifort|' configure.wrf
    sed -i 's|^DM_CC[[:space:]]*=.*|DM_CC           = mpiicc -DMPI2_SUPPORT|' configure.wrf
else
    sed -i 's|^DM_FC[[:space:]]*=.*|DM_FC           = mpif90|' configure.wrf
    sed -i 's|^DM_CC[[:space:]]*=.*|DM_CC           = mpicc -DMPI2_SUPPORT|' configure.wrf
fi

if [[ "${ENABLE_HYDRO}" == "1" && -f hydro/macros ]]; then
    if [[ "${TOOLCHAIN}" == "intel" ]]; then
        MPIF90="$(command -v mpiifort)"
    else
        MPIF90="$(command -v mpif90)"
    fi
    sed -i "s|^COMPILER90.*|COMPILER90  = ${MPIF90}|" hydro/macros
    sed -i "s|^NETCDFINC.*|NETCDFINC   = ${NETCDF}/include|" hydro/macros
    sed -i "s|^NETCDFLIB.*|NETCDFLIB   = -L${NETCDF}/lib -lnetcdff -lnetcdf|" hydro/macros
    echo "Patched hydro/macros"
fi

for pass in $(seq 1 "${MAX_PASSES}"); do
    echo "=== compile pass ${pass}/${MAX_PASSES} (-j 1) ==="
    ./compile -j 1 "${WRF_CASE}" 2>&1 | tee "compile_pass${pass}.log"
    missing=0
    for exe in wrf real ndown tc; do
        [[ -x "main/${exe}.exe" ]] || missing=1
    done
    if [[ ${missing} -eq 0 ]]; then
        echo "SUCCESS on pass ${pass}"
        break
    fi
    if [[ ${pass} -eq ${MAX_PASSES} ]]; then
        echo "ERROR: build incomplete after ${MAX_PASSES} passes"
        if [[ -x "${INSTALL_DIR}/diagnose_wrf_compile.sh" ]]; then
            bash "${INSTALL_DIR}/diagnose_wrf_compile.sh" "${WRF_DIR}" || true
        fi
        exit 3
    fi
done

mkdir -p "${INSTALL_DIR}/bin" "${INSTALL_DIR}/share/wrf"
cp -f main/wrf.exe main/real.exe main/ndown.exe main/tc.exe "${INSTALL_DIR}/bin/"
cp -f configure.wrf configure.log "compile_pass${pass}.log" "${INSTALL_DIR}/share/wrf/" 2>/dev/null || true
if [[ "${ENABLE_HYDRO}" == "1" ]]; then
    mkdir -p "${INSTALL_DIR}/share/wrf-hydro"
    cp -f hydro/template/HYDRO/* "${INSTALL_DIR}/share/wrf-hydro/" 2>/dev/null || true
fi

mkdir -p "${MODULE_DIR}"
cat > "${MODULE_DIR}/${MODULE_NAME}" <<MOD
#%Module1.0
proc ModulesHelp { } {
    puts stderr "WRF v4.7.1 ${TOOLCHAIN} hydro=${ENABLE_HYDRO} (Lengau)"
}
module-whatis "WRF v4.7.1 ${TOOLCHAIN}"
module load ${NETCDF_MODULE}
setenv WRF_ROOT ${INSTALL_DIR}
setenv WRFIO_NCD_LARGE_FILE_SUPPORT 1
prepend-path PATH ${INSTALL_DIR}/bin
MOD
if [[ "${ENABLE_HYDRO}" == "1" ]]; then
    echo "setenv WRF_HYDRO 1" >> "${MODULE_DIR}/${MODULE_NAME}"
fi

cat > "${INSTALL_DIR}/install_log.txt" <<LOG
WRF v4.7.1 build
Date: $(date)
TOOLCHAIN=${TOOLCHAIN} WRF_HYDRO=${ENABLE_HYDRO} CONFIG=${WRF_CONFIG_OPTION}
Passes=${pass}
$(ls -la ${INSTALL_DIR}/bin/*.exe)
LOG

echo "=== Build complete ==="
ls -la "${INSTALL_DIR}/bin/"*.exe
echo "Module: module load chpc/earth/${MODULE_NAME}"
