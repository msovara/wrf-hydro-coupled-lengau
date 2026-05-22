#!/bin/bash
# Diagnose WRF compile failures on Lengau.
# Usage: diagnose_wrf_compile.sh [WRF_SOURCE_DIR]
set -euo pipefail

WRF_DIR="${1:-${WRF_DIR:-/home/apps/chpc/earth/WRF-4.7.1-hydro/build/WRF}}"

echo "=== WRF compile diagnostics: ${WRF_DIR} ==="

if [[ -d "${WRF_DIR}/phys/physics_mmm/.git" ]]; then
    n_mmm=$(find "${WRF_DIR}/phys/physics_mmm" -name '*.F' -o -name '*.f90' 2>/dev/null | wc -l)
    echo "OK  phys/physics_mmm present (${n_mmm} source files)"
else
    echo "FAIL phys/physics_mmm/.git MISSING — WRF 4.7+ needs checkout_externals on DTN"
    echo "     Run: INSTALL_DIR=... ./checkout_wrf_externals_dtn.sh"
fi

for exe in wrf real ndown tc; do
    if [[ -x "${WRF_DIR}/main/${exe}.exe" ]]; then
        echo "OK  main/${exe}.exe"
    else
        echo "MISS main/${exe}.exe"
    fi
done

if [[ -f "${WRF_DIR}/main/libwrflib.a" ]]; then
    echo
    echo "libwrflib.a unresolved symbols (sample):"
    nm "${WRF_DIR}/main/libwrflib.a" 2>/dev/null | awk '/ U /{print $3}' | sort -u | head -15
    echo
    for sym in init_modules_em_ couple_or_uncouple_em_; do
        if ar t "${WRF_DIR}/main/libwrflib.a" 2>/dev/null | grep -q "${sym%.o}.o"; then
            echo "OK  ${sym%.o}.o in libwrflib.a"
        else
            if [[ -f "${WRF_DIR}/dyn_em/${sym%.o}.o" ]]; then
                echo "WARN ${sym%.o}.o exists in dyn_em/ but NOT archived in libwrflib.a"
            else
                echo "MISS ${sym%.o}.o not built"
            fi
        fi
    done
fi

latest=$(ls -1 "${WRF_DIR}"/compile_pass*.log 2>/dev/null | sort -V | tail -1)
if [[ -n "${latest}" ]]; then
    echo
    echo "Latest log: ${latest}"
    grep -E 'error #|catastrophic|undefined reference|Problems building' "${latest}" \
        | sort -u | head -20 || true
fi
