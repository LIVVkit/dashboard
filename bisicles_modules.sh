export NERSC_HOST=`/usr/common/usg/bin/nersc_host`
conda deactivate

module unload PrgEnv-gnu
module unload craype-haswell
module load PrgEnv-intel
module load craype-mic-knl
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load visit
module load python/2.7-anaconda-5.2

export PETSC_DIR=/global/common/software/m1041/petsc_install/petsc_knl_intel
export PETSC_ARCH=""
export CRAY_ROOTFS=DSL
export CRAYPE_LINK_TYPE=dynamic

module list