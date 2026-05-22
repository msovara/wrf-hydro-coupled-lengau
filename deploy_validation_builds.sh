#!/bin/bash
# Stage WRF sources with physics_mmm and submit validation builds on Lengau.
# Run on login node: bash deploy_validation_builds.sh
set -euo pipefail

BASE=/home/apps/chpc/earth
GCC_SRC=${BASE}/WRF-4.7.1-gcc/build/WRF
PLAIN=${BASE}/WRF-4.7.1-plain-intel
HYDRO_INTEL=${BASE}/WRF-4.7.1-hydro
HYDRO_GCC=${BASE}/WRF-4.7.1-hydro-gcc
SCRIPT_DIR=${BASE}/wrf-lengau-scripts

mkdir -p "${SCRIPT_DIR}"

stage_tree() {
    local dest=$1
    echo "Staging ${dest} ..."
    mkdir -p "${dest}/build"
    if [[ ! -d "${dest}/build/WRF/.git" ]]; then
        echo "  copying WRF source from gcc tree (includes physics_mmm)..."
        rsync -a --delete "${GCC_SRC}/" "${dest}/build/WRF/"
    else
        echo "  WRF source exists; syncing physics_mmm only..."
        rsync -a "${GCC_SRC}/phys/physics_mmm/" "${dest}/build/WRF/phys/physics_mmm/"
    fi
    [[ -d "${dest}/build/WRF/phys/physics_mmm/.git" ]] || {
        echo "ERROR: physics_mmm still missing in ${dest}"
        exit 1
    }
}

echo "=== Deploy WRF validation builds ==="
stage_tree "${PLAIN}"
stage_tree "${HYDRO_INTEL}"
stage_tree "${HYDRO_GCC}"

for f in install_wrf_lengau_clean.sh diagnose_wrf_compile.sh checkout_wrf_externals_dtn.sh deploy_validation_builds.sh; do
    src="${SCRIPT_DIR}/${f}"
    [[ -f "${src}.new" ]] && src="${src}.new"
    if [[ -f "${src}" ]]; then
        python3 -c "
from pathlib import Path
s=Path('${src}'); d=Path('${SCRIPT_DIR}/${f}')
d.write_bytes(s.read_bytes().replace(b'\r\n',b'\n').replace(b'\r',b'\n'))
print('installed', d)
"
        chmod +x "${SCRIPT_DIR}/${f}"
    fi
done

for dest in "${PLAIN}" "${HYDRO_INTEL}" "${HYDRO_GCC}"; do
    cp -f "${SCRIPT_DIR}/install_wrf_lengau_clean.sh" "${SCRIPT_DIR}/diagnose_wrf_compile.sh" "${dest}/"
    chmod +x "${dest}/install_wrf_lengau_clean.sh" "${dest}/diagnose_wrf_compile.sh"
done

cat > "${SCRIPT_DIR}/run_plain_intel.pbs" << 'EOF'
#!/bin/bash
#PBS -N wrf_plain_intel
#PBS -P RCHPC
#PBS -q internal
#PBS -l select=1:ncpus=24:mpiprocs=24:nodetype=haswell_reg
#PBS -l walltime=10:00:00
#PBS -W group_list=chpc_staff
#PBS -j oe
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-plain-intel
export TOOLCHAIN=intel
export WRF_HYDRO=0
export WRF_CONFIG_OPTION=66
export WRF_RUN_CLEAN=0
export MODULE_NAME=wrf-lengau-plain
cd "${INSTALL_DIR}"
bash install_wrf_lengau_clean.sh 2>&1 | tee build_plain_intel.log
EOF

cat > "${SCRIPT_DIR}/run_hydro_intel.pbs" << 'EOF'
#!/bin/bash
#PBS -N wrf_hydro_intel
#PBS -P RCHPC
#PBS -q internal
#PBS -l select=1:ncpus=24:mpiprocs=24:nodetype=haswell_reg
#PBS -l walltime=10:00:00
#PBS -W group_list=chpc_staff
#PBS -j oe
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro
export TOOLCHAIN=intel
export WRF_HYDRO=1
export WRF_CONFIG_OPTION=66
export WRF_RUN_CLEAN=0
export MODULE_NAME=wrf-hydro-coupled
cd "${INSTALL_DIR}"
bash install_wrf_lengau_clean.sh 2>&1 | tee build_hydro_intel.log
EOF

cat > "${SCRIPT_DIR}/run_hydro_gcc.pbs" << 'EOF'
#!/bin/bash
#PBS -N wrf_hydro_gcc
#PBS -P RCHPC
#PBS -q internal
#PBS -l select=1:ncpus=24:mpiprocs=24:nodetype=haswell_reg
#PBS -l walltime=10:00:00
#PBS -W group_list=chpc_staff
#PBS -j oe
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
export TOOLCHAIN=gcc
export WRF_HYDRO=1
export WRF_CONFIG_OPTION=34
export WRF_RUN_CLEAN=0
export MODULE_NAME=wrf-lengau-gcc-hydro
cd "${INSTALL_DIR}"
bash install_wrf_lengau_clean.sh 2>&1 | tee build_hydro_gcc.log
EOF

chmod +x "${SCRIPT_DIR}"/*.pbs

J1=$(cd "${SCRIPT_DIR}" && qsub run_plain_intel.pbs)
J2=$(cd "${SCRIPT_DIR}" && qsub run_hydro_intel.pbs)
J3=$(cd "${SCRIPT_DIR}" && qsub run_hydro_gcc.pbs)

echo "Submitted:"
echo "  Plain Intel (no hydro):  ${J1}"
echo "  Coupled Intel+hydro:     ${J2}"
echo "  Coupled GCC+hydro:       ${J3}"
