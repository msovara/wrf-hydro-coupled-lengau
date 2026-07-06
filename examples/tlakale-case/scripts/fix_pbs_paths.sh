#!/bin/bash
# One-time fix for PBS scripts when deployed to tmogebisa lustre.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW='/home/tmogebisa/lustre/WRF-Hydro_Coupled/examples/tlakale-case'
for f in run_wrf.pbs run_real.pbs run_wps.pbs; do
  sed -i "s|^EXAMPLE_DIR=.*|EXAMPLE_DIR=\"\${EXAMPLE_DIR:-${NEW}}\"|" "${DIR}/${f}"
done
echo "Updated EXAMPLE_DIR in PBS scripts to ${NEW}"
