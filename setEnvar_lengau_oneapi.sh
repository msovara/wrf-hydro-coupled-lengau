#!/bin/bash
# Environment for standalone WRF-Hydro builds on Lengau (oneAPI 2021.3).
# Source this file or pass it to compile_offline_NoahMP.sh / compile_offline_Noah.sh

ONEAPI_2021="${ONEAPI_2021:-/home/apps/chpc/compmech/compilers/intel_2021.3/oneapi}"
NETCDF_MODULE="${NETCDF_MODULE:-chpc/earth/netcdf/4.9.2-intel2021.3}"

module purge 2>/dev/null || true
set +u
source "${ONEAPI_2021}/compiler/2021.3.0/env/vars.sh" >/dev/null
source "${ONEAPI_2021}/mpi/2021.3.0/env/vars.sh" >/dev/null
set -u
module load "${NETCDF_MODULE}"

export NETCDF="${NETCDF_ROOT:?NETCDF_ROOT not set by ${NETCDF_MODULE}}"
export NETCDF_DIR="${NETCDF}"
export NETCDF_INC="${NETCDF}/include"
export NETCDF_LIB="${NETCDF}/lib"
export LD_LIBRARY_PATH="${NETCDF}/lib:${NETCDF}/hdf5/lib:${LD_LIBRARY_PATH:-}"

export FC=ifort
export CC=icc
export CXX=icpc
export F77=ifort
export F90=ifort
export MPICC=mpiicc
export MPICXX=mpiicpc
export MPIFC=mpiifort
export MPIF90=mpiifort
export MPIF77=mpiifort

# Required for WRF-Hydro standalone compile scripts
export WRF_HYDRO=1
export HYDRO_D="${HYDRO_D:-1}"
export HYDRO_LSM="${HYDRO_LSM:-NoahMP}"
export NWM_META="${NWM_META:-0}"
export WRFIO_NCD_LARGE_FILE_SUPPORT=1
