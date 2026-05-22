# WRF Configuration Guide

This guide explains configuration options for WRF installation on Lengau cluster.

## Installation Paths

### Default Paths

- **Installation Directory**: `/home/apps/chpc/earth/WRF-4.7.1`
- **Build Directory**: `/home/apps/chpc/earth/WRF-4.7.1/build`
- **Module Directory**: `/apps/chpc/scripts/modules/earth`

### Customizing Installation Directory

Edit `install_wrf_lengau.sh`:

```bash
INSTALL_DIR="/path/to/custom/location"
MODULE_DIR="/path/to/custom/modules"
```

## WRF Version

### Current Version

- **WRF Version**: v4.7.1 (latest as of December 2025)

### Changing Version

Edit `download_wrf_source.sh` and `install_wrf_lengau.sh`:

```bash
WRF_VERSION="v4.6.0"  # Change to desired version
```

## Compiler Configuration

### Intel Compiler Version

Default: Intel Parallel Studio XE 2016.1.150

The script automatically loads:
```bash
module load chpc/parallel_studio_xe/16.0.1/2016.1.150
```

### Forcing Specific Compiler

Edit `install_wrf_lengau.sh` to change module loading:

```bash
# Change this line:
module load chpc/parallel_studio_xe/16.0.1/2016.1.150

# To:
module load chpc/parallel_studio_xe/18.0.2/2018.2.046
```

## Module Selection

### NetCDF Version

The script tries multiple NetCDF versions:
1. `chpc/netcdf/4.7.4`
2. `chpc/netcdf/4.4.3-F/intel/16.0.1`
3. `chpc/netcdf/4.4.0-C/intel/16.0.1`

### HDF5 Version

The script tries multiple HDF5 versions:
1. `chpc/hdf5/1.12.0`
2. `chpc/hdf5/1.8.16/intel/16.0.1`

## Build Options

### WRF Configuration Option

Default: Option 15 (dmpar INTEL)

To change, edit `install_wrf_lengau.sh`:

```bash
# Change this line:
printf "15\n1\n" | ./configure

# To other options:
# 35 = (dmpar) INTEL oneAPI
# 34 = (smpar) INTEL
# etc.
```

### Compilation Case

Default: `em_real` (real data case)

To change, edit `install_wrf_lengau.sh`:

```bash
# Change this line:
./compile -j ${NUM_CORES} em_real

# To other cases:
# em_quarter_ss = quarter SS case
# em_b_wave = baroclinic wave
# nmm_real = NMM real data
```

### Parallel Compilation

Default: Uses all available cores (`nproc`)

To change number of cores:

```bash
NUM_CORES=8  # Use 8 cores instead
./compile -j ${NUM_CORES} em_real
```

## Environment Variables

### Compiler Flags

Default flags:
- `FCFLAGS="-O2 -xHost -qopenmp"`
- `CFLAGS="-O2 -xHost -qopenmp"`
- `CXXFLAGS="-O2 -xHost -qopenmp"`

To customize, edit `install_wrf_lengau.sh`:

```bash
export FCFLAGS="-O3 -xHost -qopenmp -ipo"
```

### WRF-Specific Variables

- `WRFIO_NCD_LARGE_FILE_SUPPORT=1`: Enable large file support
- `JASPERLIB=/usr/lib64`: Jasper library path
- `JASPERINC=/usr/include`: Jasper include path

## Module File Configuration

### Module File Location

Default: `/apps/chpc/scripts/modules/earth/wrf-lengau`

### Customizing Module File

The module file is automatically generated. To customize, edit the template in `install_wrf_lengau.sh`:

```bash
cat > ${MODULE_DIR}/wrf-lengau << EOF
#%Module1.0
# ... module file content ...
EOF
```

## Build Parallelization

### Number of Cores

Default: All available cores (`nproc`)

To limit cores:

```bash
NUM_CORES=16  # Use 16 cores
./compile -j ${NUM_CORES} em_real
```

## Installation Verification

### Test After Installation

```bash
# Load module
module load chpc/earth/wrf-lengau

# Check executables
ls -la $WRF_ROOT/bin/*.exe

# Should see:
# - wrf.exe
# - real.exe
# - ideal.exe
# - etc.
```

## Advanced Configuration

### Custom WRF Options

Edit `configure.wrf` after configuration:

```bash
cd /home/apps/chpc/earth/WRF-4.7.1/build/WRF
# Edit configure.wrf manually
# Then recompile
./compile em_real
```

### Git Configuration

For SSL issues, the script uses:
```bash
GIT_SSL_NO_VERIFY=1 git clone ...
```

## Configuration Examples

### Minimal Installation

```bash
# Use default settings
./install_wrf_lengau.sh
```

### Full-Featured Installation

```bash
# Edit script to:
# - Use more optimization flags
# - Enable additional features
# - Customize paths
```

## Saving Configuration

### Create Config File

Save your configuration:

```bash
cat > wrf_config.sh << EOF
export WRF_VERSION="v4.7.1"
export INSTALL_DIR="/home/apps/chpc/earth/WRF-4.7.1"
export NUM_CORES=24
EOF

source wrf_config.sh
```

## Best Practices

1. **Use consistent paths**: Keep installation and module paths consistent
2. **Document changes**: Note any customizations
3. **Test after changes**: Verify installation after modifications
4. **Keep backups**: Backup configure.wrf before changes
















