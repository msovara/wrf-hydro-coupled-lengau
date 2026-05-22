#!/bin/bash
# ---------------------------------------------------------------------------
# Standalone WRF-Hydro on CHPC Lengau (Intel oneAPI 2021.3 + NetCDF 4.9.2)
#
# Uses the legacy make-based build in wrf_hydro_nwm_public v5.3.x:
#   trunk/NDHMS/configure  ->  compile_offline_NoahMP.sh
#
# Run on a compute node after source is present under HYDRO_SRC.
# ---------------------------------------------------------------------------
set -euo pipefail

HYDRO_ROOT="${HYDRO_ROOT:-/mnt/lustre/users/${USER}/SoftwareBuilds/WRF-HYDRO}"
HYDRO_SRC="${HYDRO_SRC:-${HYDRO_ROOT}/wrf_hydro_nwm_public-5.3.0/trunk/NDHMS}"
NDHMS_DIR="${HYDRO_SRC}"
INSTALL_DIR="${INSTALL_DIR:-/home/apps/chpc/earth/WRF-Hydro-5.3.0-standalone-intel2021.3}"
MODULE_DIR="${MODULE_DIR:-/apps/chpc/scripts/modules/earth}"
ENV_FILE="${ENV_FILE:-${HYDRO_ROOT}/setEnvar_lengau_oneapi.sh}"
LAND_MODEL="${LAND_MODEL:-NoahMP}"   # Noah or NoahMP
NUM_CORES="${NUM_CORES:-4}"

echo "=== WRF-Hydro standalone installer (oneAPI 2021.3) ==="
echo "NDHMS_DIR   = ${NDHMS_DIR}"
echo "INSTALL_DIR = ${INSTALL_DIR}"
echo "LAND_MODEL  = ${LAND_MODEL}"
echo "ENV_FILE    = ${ENV_FILE}"
echo

[[ -d "${NDHMS_DIR}" ]] || {
    echo "ERROR: ${NDHMS_DIR} not found."
    echo "Download v5.3.0 on DTN:"
    echo "  cd ${HYDRO_ROOT}"
    echo "  wget https://github.com/NCAR/wrf_hydro_nwm_public/archive/refs/tags/v5.3.0.tar.gz"
    echo "  tar zxf v5.3.0.tar.gz"
    exit 1
}
[[ -f "${ENV_FILE}" ]] || { echo "ERROR: ${ENV_FILE} missing"; exit 1; }

# shellcheck disable=SC1090
source "${ENV_FILE}"

echo "Toolchain:"
which mpiifort
mpiifort --version | head -1
echo "NETCDF = ${NETCDF}"
echo

cd "${NDHMS_DIR}"

echo "Cleaning previous standalone build artifacts..."
rm -f Makefile compile_options.json LandModel LandModel_cpl 2>/dev/null || true
make clean >/dev/null 2>&1 || true
rm -rf lib mod Run/wrf_hydro*.exe Run/*TBL Run/*namelist* 2>/dev/null || true

echo "Running WRF-Hydro configure (ifort parallel = option 3)..."
printf '3\n' | ./configure 2>&1 | tee configure.log
[[ -f macros ]] || { echo "ERROR: macros not produced — see configure.log"; exit 2; }

# arc/macros.mpp.ifort ships with stale CHPC Parallel Studio / WRFHYDRO paths.
MPIIFORT="$(command -v mpiifort)"
sed -i "s|^COMPILER90.*|COMPILER90  = ${MPIIFORT}|" macros
sed -i "s|^NETCDFINC.*|NETCDFINC   = ${NETCDF}/include|" macros
sed -i "s|^NETCDFLIB.*|NETCDFLIB   = -L${NETCDF}/lib -lnetcdff -lnetcdf|" macros
echo "Patched macros for oneAPI NetCDF:"
grep -E '^COMPILER90|^NETCDF' macros

export NWM_META="${NWM_META:-0}"

if [[ "${LAND_MODEL}" == "NoahMP" ]]; then
    COMPILE_SCRIPT="./compile_offline_NoahMP.sh"
elif [[ "${LAND_MODEL}" == "Noah" ]]; then
    COMPILE_SCRIPT="./compile_offline_Noah.sh"
else
    echo "ERROR: LAND_MODEL must be Noah or NoahMP"
    exit 2
fi

echo "Compiling standalone WRF-Hydro (${LAND_MODEL})..."
set +e
"${COMPILE_SCRIPT}" "${ENV_FILE}" 2>&1 | tee compile.log
set -e

EXE="${NDHMS_DIR}/Run/wrf_hydro.exe"
[[ -x "${EXE}" ]] || {
    echo "ERROR: ${EXE} not produced"
    grep -E 'error #|Error|FAILED' compile.log | tail -20 || true
    exit 3
}

echo
echo "Build succeeded: ${EXE}"
ls -la "${NDHMS_DIR}"/Run/wrf_hydro*.exe

mkdir -p "${INSTALL_DIR}/bin" "${INSTALL_DIR}/Run"
cp -f "${NDHMS_DIR}"/Run/wrf_hydro*.exe "${INSTALL_DIR}/bin/"
cp -f "${NDHMS_DIR}"/Run/*.TBL "${INSTALL_DIR}/Run/" 2>/dev/null || true
cp -f "${NDHMS_DIR}"/Run/*namelist* "${INSTALL_DIR}/Run/" 2>/dev/null || true
cp -f configure.log compile.log "${INSTALL_DIR}/" 2>/dev/null || true

cat > "${INSTALL_DIR}/setup_wrf_hydro.sh" <<SETUP
#!/bin/bash
source ${ENV_FILE}
export WRF_HYDRO_ROOT=${INSTALL_DIR}
export PATH=\${WRF_HYDRO_ROOT}/bin:\${PATH}
echo "WRF-Hydro standalone ready: \${WRF_HYDRO_ROOT}/bin"
ls -1 \${WRF_HYDRO_ROOT}/bin/wrf_hydro*.exe 2>/dev/null
SETUP
chmod +x "${INSTALL_DIR}/setup_wrf_hydro.sh"

mkdir -p "${MODULE_DIR}"
cat > "${MODULE_DIR}/wrf-hydro-standalone" <<MODFILE
#%Module1.0
proc ModulesHelp { } {
    puts stderr "Standalone WRF-Hydro 5.3.x (NoahMP) — Intel oneAPI 2021.3"
    puts stderr "Tables/namelists: ${INSTALL_DIR}/Run"
    puts stderr "Source: ${ENV_FILE}"
}
module-whatis "WRF-Hydro standalone 5.3.x (Lengau, oneAPI 2021.3)"
module load ${NETCDF_MODULE:-chpc/earth/netcdf/4.9.2-intel2021.3}
setenv WRF_HYDRO_ROOT ${INSTALL_DIR}
prepend-path PATH ${INSTALL_DIR}/bin
MODFILE

echo
echo "=== WRF-Hydro standalone install complete ==="
echo "Executable : ${INSTALL_DIR}/bin/"
echo "Run files  : ${INSTALL_DIR}/Run/"
echo "Module     : module load chpc/earth/wrf-hydro-standalone"
echo "Setup      : source ${INSTALL_DIR}/setup_wrf_hydro.sh"
