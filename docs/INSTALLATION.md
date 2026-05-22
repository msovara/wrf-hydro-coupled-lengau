# WRF Installation Guide for Lengau Cluster

This guide provides detailed instructions for installing WRF v4.7.1 on the Lengau cluster.

## Prerequisites

- Access to Lengau cluster
- SSH access to DTN node
- Sufficient disk space (~15 GB)
- PBS job allocation for compilation

## Installation Steps

### Step 1: Download Source Code (DTN Node)

**Important**: Compute nodes have no internet access. All downloads must be done on the DTN node.

```bash
# SSH to DTN node
ssh msovara@dtn.chpc.ac.za

# Navigate to installation directory
cd /home/apps/chpc/earth/WRF-4.7.1

# Copy download script
cp ~/wrf-lengau/download_wrf_source.sh .

# Make executable
chmod +x download_wrf_source.sh

# Download WRF source code
./download_wrf_source.sh
```

This will:
- Clone WRF repository from GitHub
- Checkout WRF v4.7.1
- Initialize and update git submodules (NoahMP, etc.)

### Step 2: Install WRF (Compute Node)

```bash
# Request interactive compute node
qsub -I -l select=1:ncpus=24:mpiprocs=24 -l walltime=08:00:00 -q normal

# Navigate to installation directory
cd /home/apps/chpc/earth/WRF-4.7.1

# Copy installation script
cp ~/wrf-lengau/install_wrf_lengau.sh .

# Make executable
chmod +x install_wrf_lengau.sh

# Run installation
./install_wrf_lengau.sh
```

The installation script will:
1. Load required modules (Intel, NetCDF, HDF5)
2. Configure WRF for Intel compilers with distributed memory
3. Compile WRF (takes 4-8 hours)
4. Install executables to `/home/apps/chpc/earth/WRF-4.7.1/bin`
5. Create module file at `/apps/chpc/scripts/modules/earth/wrf-lengau`

### Step 3: Verify Installation

```bash
# Load WRF module
module load chpc/earth/wrf-lengau

# Check executables
ls -la $WRF_ROOT/bin/*.exe

# Should see:
# - wrf.exe
# - real.exe
# - ideal.exe
# - etc.
```

## Installation Paths

- **Installation Directory**: `/home/apps/chpc/earth/WRF-4.7.1`
- **Build Directory**: `/home/apps/chpc/earth/WRF-4.7.1/build`
- **Module File**: `/apps/chpc/scripts/modules/earth/wrf-lengau`
- **Executables**: `/home/apps/chpc/earth/WRF-4.7.1/bin`

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

## Next Steps

After installation:
1. Install WPS (WRF Preprocessing System) if needed
2. Prepare input data (GRIB files, etc.)
3. Configure namelist files
4. Run WRF simulations

See [USAGE.md](USAGE.md) for usage instructions.
















