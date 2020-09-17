export NERSC_HOST=`/usr/common/usg/bin/nersc_host`
module unload PrgEnv-gnu
module unload craype-haswell
module load PrgEnv-intel
module load craype-mic-knl
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load visit

export PETSC_DIR=/global/common/software/m1041/petsc_install/petsc_knl_intel
export PETSC_ARCH=""
export CRAY_ROOTFS=DSL
export CRAYPE_LINK_TYPE=dynamic

export LD_LIBRARY_PATH=${PYTHON_DIR}/lib:${LD_LIBRARY_PATH}
module list