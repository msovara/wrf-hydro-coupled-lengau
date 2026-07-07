# Upload tlakale-case (+ optional data) to Lengau from Windows PC.
# Usage:
#   .\deploy_to_lengau.ps1
#   .\deploy_to_lengau.ps1 -IncludeGis
#   .\deploy_to_lengau.ps1 -DemPath "C:\data\inkomati_dem.tif"

param(
    [string]$RemoteUser = "msovara",
    [string]$RemoteHost = "lengau.chpc.ac.za",
    [string]$LustreBase = "/home/tmogebisa/lustre/WRF-Hydro_Coupled",
    [switch]$IncludeGis,
    [string]$DemPath = ""
)

$CaseDir = Join-Path $PSScriptRoot ".."
$CaseDir = (Resolve-Path $CaseDir).Path

Write-Host "Uploading tlakale-case to ${RemoteUser}@${RemoteHost}:${LustreBase}/examples/"
scp -r "$CaseDir" "${RemoteUser}@${RemoteHost}:${LustreBase}/examples/tlakale-case"

if ($IncludeGis) {
    Write-Host "GIS bundle included in tlakale-case/gis/ (clone locally first if missing)"
}

if ($DemPath -ne "" -and (Test-Path $DemPath)) {
    Write-Host "Uploading DEM..."
    ssh "${RemoteUser}@${RemoteHost}" "mkdir -p ${LustreBase}/dem"
    scp "$DemPath" "${RemoteUser}@${RemoteHost}:${LustreBase}/dem/inkomati_dem.tif"
}

Write-Host "Done. On Lengau, tmogebisa should run:"
Write-Host "  chmod +x ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/*.sh"
Write-Host "  SIM_MODE=test bash ~/lustre/WRF-Hydro_Coupled/examples/tlakale-case/scripts/apply_namelists.sh"
