#!/bin/bash
# List WRF-Hydro routing / LSM output files in the case directory.
set -euo pipefail

CASE_DIR="${1:-${CASE_DIR:-.}}"

echo "=== Hydro outputs in ${CASE_DIR} ==="
found=0
for pat in CHRTOUT LSMOUT RTOUT GWOUT; do
  shopt -s nullglob
  files=( "${CASE_DIR}/${pat}"* )
  if (( ${#files[@]} > 0 )); then
    found=1
    ls -lh "${files[@]}"
  else
    echo "MISSING: ${pat}*"
  fi
done

echo "=== RESTART/HYDRO_RST ==="
if compgen -G "${CASE_DIR}/RESTART/HYDRO_RST*" > /dev/null; then
  ls -lh "${CASE_DIR}"/RESTART/HYDRO_RST*
else
  echo "MISSING: RESTART/HYDRO_RST*"
fi

if (( found == 0 )); then
  exit 1
fi
