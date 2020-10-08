module unload intel PrgEnv-intel
module load PrgEnv-gnu
module load cmake
module load boost
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
module load cray-tpsl
# module load python

export CRAYPE_LINK_TYPE=STATIC
module list
