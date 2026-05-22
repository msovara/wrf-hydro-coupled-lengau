# WRF Troubleshooting Guide

This guide addresses common issues encountered during WRF installation on Lengau cluster.

## Pre-Installation Issues

### Issue: Cannot Access DTN Node

**Symptoms:**
```
ssh: Could not resolve hostname dtn.chpc.ac.za
```

**Solutions:**
1. Ensure you're on CHPC network or using VPN
2. Check SSH configuration
3. Contact CHPC support for network access

### Issue: Insufficient Disk Space

**Symptoms:**
```
No space left on device
```

**Solutions:**
1. Check available space: `df -h /home/apps/chpc/earth/WRF-4.7.1`
2. Clean up old builds: `rm -rf /home/apps/chpc/earth/WRF-4.7.1/build/build_*`
3. Request quota increase from CHPC

## Download Issues

### Issue: Git Clone Fails on DTN Node

**Symptoms:**
```
fatal: unable to access 'https://github.com/...': SSL certificate problem
```

**Solutions:**
1. Use `GIT_SSL_NO_VERIFY=1` (already in script)
2. Check network connectivity: `ping github.com`
3. Try using SSH instead of HTTPS (modify script)

### Issue: Submodule Update Fails

**Symptoms:**
```
fatal: clone of 'https://github.com/...' into submodule path failed
```

**Solutions:**
1. Manually clone submodules:
   ```bash
   cd WRF
   git submodule update --init --recursive
   ```
2. Check network connectivity
3. Retry with `GIT_SSL_NO_VERIFY=1`

## Compilation Issues

### Issue: Module Not Found

**Symptoms:**
```
module: command not found
```

**Solutions:**
1. Source module system:
   ```bash
   source /etc/profile.d/modules.sh
   ```
2. Check module system: `module avail`

### Issue: Intel Compiler Not Found

**Symptoms:**
```
ifort: command not found
```

**Solutions:**
1. Load Intel module:
   ```bash
   module load chpc/parallel_studio_xe/16.0.1/2016.1.150
   ```
2. Verify: `which ifort`
3. Check module availability: `module avail parallel_studio_xe`

### Issue: NetCDF Not Found

**Symptoms:**
```
WRF configure: NETCDF not found
```

**Solutions:**
1. Load NetCDF module:
   ```bash
   module load chpc/netcdf/4.7.4
   ```
2. Set NETCDF environment variable:
   ```bash
   export NETCDF=/apps/libs/netcdf/4.4.0
   ```
3. Check NetCDF location: `find /apps -name "libnetcdf.a" 2>/dev/null`

### Issue: Configure Fails

**Symptoms:**
```
configure.wrf not created
```

**Solutions:**
1. Ensure NETCDF is set: `echo $NETCDF`
2. Run configure interactively:
   ```bash
   ./configure
   # Select option 15 (dmpar INTEL)
   # Select option 1 (Basic nesting)
   ```
3. Check configure.log for errors

### Issue: Compilation Fails

**Symptoms:**
```
Compilation errors in compile.log
```

**Solutions:**
1. Check compile.log for specific errors
2. Ensure all submodules are initialized:
   ```bash
   git submodule update --init --recursive
   ```
3. Try sequential compilation:
   ```bash
   ./compile em_real
   ```
4. Check for memory issues (try fewer cores)

## Runtime Issues

### Issue: Executable Not Found

**Symptoms:**
```
wrf.exe: command not found
```

**Solutions:**
1. Load WRF module:
   ```bash
   module load chpc/earth/wrf-lengau
   ```
2. Or source setup script:
   ```bash
   source /home/apps/chpc/earth/WRF-4.7.1/setup_wrf_lengau.sh
   ```
3. Verify: `which wrf.exe`

### Issue: Library Not Found

**Symptoms:**
```
error while loading shared libraries: libnetcdf.so: cannot open shared object file
```

**Solutions:**
1. Ensure NetCDF module is loaded
2. Check LD_LIBRARY_PATH:
   ```bash
   echo $LD_LIBRARY_PATH | grep netcdf
   ```
3. Manually add if needed:
   ```bash
   export LD_LIBRARY_PATH=/apps/libs/netcdf/4.4.0/lib:$LD_LIBRARY_PATH
   ```

## Module System Issues

### Issue: Module File Not Found

**Symptoms:**
```
module: ERROR:105: Unable to locate a modulefile
```

**Solutions:**
1. Check module file exists:
   ```bash
   ls -la /apps/chpc/scripts/modules/earth/wrf-lengau
   ```
2. Re-run installation script to regenerate module file
3. Use setup script instead:
   ```bash
   source /home/apps/chpc/earth/WRF-4.7.1/setup_wrf_lengau.sh
   ```

### Issue: Module Conflicts

**Symptoms:**
```
module: ERROR:102: Tcl command execution failed
```

**Solutions:**
1. Purge modules before loading:
   ```bash
   module purge
   module load chpc/parallel_studio_xe/16.0.1/2016.1.150
   module load chpc/earth/wrf-lengau
   ```

## Getting Help

If issues persist:

1. Check installation log:
   ```bash
   cat /home/apps/chpc/earth/WRF-4.7.1/install_log.txt
   ```

2. Enable debug mode:
   ```bash
   bash -x install_wrf_lengau.sh
   ```

3. Open an issue on GitHub with:
   - Error messages
   - Installation log
   - System information
   - Steps to reproduce

4. Contact CHPC support for cluster-specific issues
















