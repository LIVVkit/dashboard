module purge
module unload cmake cray-netcdf-hdf5parallel python
module unload intel PrgEnv-intel
module load PrgEnv-gnu
module unload cray-mpich
module load cray-mpich/7.7.19
module unload gcc
module load gcc/8.3.0
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
# module load cray-python/2.7.15.7
export PATH=/project/projectdirs/piscees/tpl/cmake-3.18.0/bin:$PATH

export CRAYPE_LINK_TYPE=DYNAMIC
export CRAY_CPU_TARGET=$(uname -p)
module list -l
cmake --version