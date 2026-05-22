# WRF Usage Guide

This guide explains how to use WRF after installation on Lengau cluster.

## Loading WRF Environment

### Option 1: Module System

```bash
module load chpc/earth/wrf-lengau
```

### Option 2: Setup Script

```bash
source /home/apps/chpc/earth/WRF-4.7.1/setup_wrf_lengau.sh
```

### Verify Installation

```bash
# Check executable location
which wrf.exe

# Should output:
# /home/apps/chpc/earth/WRF-4.7.1/bin/wrf.exe
```

## Running WRF

### Basic Workflow

1. **Prepare Input Data** (using WPS)
2. **Run real.exe** (process real data)
3. **Run wrf.exe** (run WRF model)

### Example PBS Job Script

```bash
#!/bin/bash
#PBS -N wrf_run
#PBS -l select=2:ncpus=24:mpiprocs=24
#PBS -l walltime=04:00:00
#PBS -q normal
#PBS -o wrf.out
#PBS -e wrf.err

# Load modules
module load chpc/parallel_studio_xe/16.0.1/2016.1.150
module load chpc/earth/wrf-lengau

# Set working directory
cd $PBS_O_WORKDIR

# Run WRF
mpirun -np 48 wrf.exe
```

### Interactive Run

```bash
# Request interactive node
qsub -I -l select=1:ncpus=4:mpiprocs=4 -l walltime=01:00:00 -q normal

# Once on compute node
module load chpc/parallel_studio_xe/16.0.1/2016.1.150
module load chpc/earth/wrf-lengau
cd ~/wrf_run
mpirun -np 4 wrf.exe
```

## WRF Executables

- **real.exe**: Processes real atmospheric data
- **wrf.exe**: Main WRF model executable
- **ideal.exe**: Idealized case simulations
- **ndown.exe**: Nested domain downscaling
- **tc.exe**: Tropical cyclone initialization

## Environment Variables

After loading WRF module:

- `WRF_ROOT`: Installation root directory
- `WRF_VERSION`: WRF version (v4.7.1)
- `WRF_COMPILER`: Compiler used (intel-2016.1.150)
- `WRFIO_NCD_LARGE_FILE_SUPPORT`: Large file support enabled
- `PATH`: Includes `$WRF_ROOT/bin`
- `LD_LIBRARY_PATH`: Includes WRF libraries

## Best Practices

1. **Always use mpirun/mpiexec**: WRF is an MPI application
2. **Load modules in order**: Intel MPI first, then WRF
3. **Use PBS for production runs**: Better resource management
4. **Check output files**: Monitor `.out` and `.err` files
5. **Test with small cases first**: Before running large jobs

## Getting Help

- Check installation log: `/home/apps/chpc/earth/WRF-4.7.1/install_log.txt`
- See troubleshooting guide: `docs/TROUBLESHOOTING.md`
- WRF documentation: https://www2.mmm.ucar.edu/wrf/users/
- CHPC support: For cluster-specific issues
















