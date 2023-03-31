module purge
module load PrgEnv-gnu
# module swap gcc/11.2.0 gcc/10.3.0
module load cray-mpich/8.1.22
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load cray-parallel-netcdf
# module load boost/1.78.0-gnu
module load cmake/3.24.3

export CRAYPE_LINK_TYPE=DYNAMIC
export CRAY_CPU_TARGET=$(uname -p)

module -t list
cmake --version