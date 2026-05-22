# Changelog

## [1.0.0] — 2026-05-21

### Added
- Coupled WRF 4.7.1 + WRF-Hydro GCC build scripts for CHPC Lengau
- Comprehensive user guide (`docs/USER_GUIDE.md`)
- PBS examples for build and simulation
- Installation verification script
- DTN externals checkout for WRF 4.7+ `phys/physics_mmm`

### Verified on Lengau
- Coupled GCC build: `/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc`
- Module: `chpc/earth/wrf-lengau-gcc-hydro`
- `wrf.exe` with `-DWRF_HYDRO` — compile pass 1 success

### Known issues
- Intel coupled build fails with `dyn_em` linker errors
- Intel standalone `wrf_hydro.exe` works separately (oneAPI 2021.3)
