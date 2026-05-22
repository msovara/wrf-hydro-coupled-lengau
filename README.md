# WRF-Hydro Coupled on CHPC Lengau

[![CHPC Lengau](https://img.shields.io/badge/Cluster-Lengau-blue)](https://www.chpc.ac.za/)
[![WRF 4.7.1](https://img.shields.io/badge/WRF-4.7.1-green)](https://github.com/wrf-model/WRF)
[![WRF-Hydro](https://img.shields.io/badge/WRF--Hydro-coupled-orange)](https://wrf-hydro.readthedocs.io/)

Build scripts and documentation for **coupled WRF 4.7.1 + WRF-Hydro** on the CHPC Lengau cluster.

This repository documents the **verified GCC coupled build** that produces `wrf.exe` with routing compiled in (`-DWRF_HYDRO`).

## Verified install (Lengau)

| Item | Value |
|------|-------|
| Path | `/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc` |
| Module | `module load chpc/earth/wrf-lengau-gcc-hydro` |
| Compiler | GCC 8.3 + MPICH (configure option 34) |
| Executables | `wrf.exe`, `real.exe`, `ndown.exe`, `tc.exe` |

```bash
module load chpc/earth/wrf-lengau-gcc-hydro
bash examples/verify_installation.sh
```

## Documentation

| Guide | Description |
|-------|-------------|
| **[docs/USER_GUIDE.md](docs/USER_GUIDE.md)** | **Start here** — full install, run, PBS, and troubleshooting |
| [docs/WRF_HYDRO_INSTALLATION.md](docs/WRF_HYDRO_INSTALLATION.md) | Build notes (coupled + standalone) |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common cluster issues |

## Quick install

```bash
# 1. DTN — download source + MMM physics externals
ssh dtn.chpc.ac.za
export INSTALL_DIR=/home/apps/chpc/earth/WRF-4.7.1-hydro-gcc
./download_wrf_source.sh
./checkout_wrf_externals_dtn.sh

# 2. Compute node — build coupled WRF-Hydro (GCC)
qsub examples/run_coupled_hydro_gcc.pbs
```

See [docs/USER_GUIDE.md](docs/USER_GUIDE.md) for complete steps.

## Repository layout

```
wrf-hydro-coupled-lengau/
├── README.md
├── install_wrf_lengau_clean.sh      # Main build script (GCC/Intel, hydro on/off)
├── checkout_wrf_externals_dtn.sh    # Required MMM physics checkout (DTN)
├── download_wrf_source.sh           # Clone WRF v4.7.1 (DTN)
├── diagnose_wrf_compile.sh          # Post-failure diagnostics
├── fix_crlf_clean.py                # Fix Windows line endings
├── docs/
│   └── USER_GUIDE.md                # Comprehensive user guide
└── examples/
    ├── run_coupled_hydro_gcc.pbs    # PBS build job
    ├── run_wrf_coupled.pbs          # PBS simulation template
    └── verify_installation.sh       # Post-install checks
```

## Coupled vs standalone

| Mode | Executable | This repo |
|------|------------|-----------|
| **Coupled** (WRF + hydro in one) | `wrf.exe` | **Primary focus — GCC build working** |
| Standalone (offline hydro only) | `wrf_hydro.exe` | See `install_wrf_hydro_standalone_lengau.sh` |

## Known status (May 2026)

| Build | Status |
|-------|--------|
| Coupled GCC + hydro | **Working** |
| Coupled Intel + hydro | Not working (linker errors) |
| Standalone WRF-Hydro (Intel) | Working (separate install) |

## License

MIT — see [LICENSE](LICENSE).

## References

- [WRF-Hydro docs](https://wrf-hydro.readthedocs.io/)
- [WRF User's Guide](https://www2.mmm.ucar.edu/wrf/users/)
- [CHPC](https://www.chpc.ac.za/)
