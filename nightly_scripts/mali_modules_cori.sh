module purge
module load spack
module unload cmake cray-netcdf-hdf5parallel python
module unload intel PrgEnv-intel
module load PrgEnv-gnu
module unload cray-mpich
module load cray-mpich/7.7.19
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
export CRAYPE_LINK_TYPE=DYNAMIC
export CRAY_CPU_TARGET=$(uname -p)

module list -l
cmake --version
