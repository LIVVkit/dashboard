module unload intel PrgEnv-intel
module load PrgEnv-gnu
module load cmake/3.21.3
module load boost
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
module load cray-tpsl
# module load python
module unload craype-hugepages2M
module load darshan

export CRAYPE_LINK_TYPE=STATIC
module list
