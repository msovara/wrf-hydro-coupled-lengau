#!/bin/bash
# Verify coupled WRF-Hydro (GCC) installation on Lengau.
set -euo pipefail

WRF_ROOT="${WRF_ROOT:-/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc}"
FAIL=0

check() {
    if eval "$2"; then
        echo "OK   $1"
    else
        echo "FAIL $1"
        FAIL=1
    fi
}

echo "=== WRF-Hydro coupled installation check ==="
echo "WRF_ROOT = ${WRF_ROOT}"
echo

check "wrf.exe exists"        "test -x ${WRF_ROOT}/bin/wrf.exe"
check "real.exe exists"       "test -x ${WRF_ROOT}/bin/real.exe"
check "ndown.exe exists"      "test -x ${WRF_ROOT}/bin/ndown.exe"
check "tc.exe exists"         "test -x ${WRF_ROOT}/bin/tc.exe"
check "configure.wrf archived"  "test -f ${WRF_ROOT}/share/wrf/configure.wrf"
check "WRF_HYDRO in configure" "grep -q WRF_HYDRO ${WRF_ROOT}/share/wrf/configure.wrf 2>/dev/null"
check "physics_mmm present"   "test -d ${WRF_ROOT}/build/WRF/phys/physics_mmm/.git"
check "hydro templates"       "test -d ${WRF_ROOT}/share/wrf-hydro && ls ${WRF_ROOT}/share/wrf-hydro/ | grep -q ."

if command -v wrf.exe &>/dev/null; then
    echo "OK   wrf.exe in PATH ($(which wrf.exe))"
else
    echo "WARN wrf.exe not in PATH — run: module load chpc/earth/wrf-lengau-gcc-hydro"
fi

echo
if [[ ${FAIL} -eq 0 ]]; then
    echo "All checks passed."
    ls -lh "${WRF_ROOT}/bin/"*.exe
    exit 0
else
    echo "One or more checks failed."
    exit 1
fi
