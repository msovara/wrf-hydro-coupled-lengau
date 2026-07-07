#!/bin/bash
CONFIG="/home/tmogebisa/lustre/WRF-Hydro_Coupled/examples/tlakale-case/config.env"
sed -i '/^export DEM_PATH=/d' "${CONFIG}"
echo 'export DEM_PATH="${DEM_PATH:-/home/tmogebisa/lustre/WRF-Hydro_Coupled/dem/inkomati_dem.tif}"' >> "${CONFIG}"
grep DEM_PATH "${CONFIG}"
