export NERSC_HOST=`/usr/common/usg/bin/nersc_host`

module unload PrgEnv-gnu
module unload craype-haswell
module load PrgEnv-intel
module load craype-mic-knl
module load cray-hdf5-parallel
module load cray-netcdf-hdf5parallel
module load visit
# module load python3/3.7-anaconda-2019.10

export PYTHON_DIR=$HOME/.conda/envs/pyctest
export PETSC_DIR=/global/common/software/m1041/petsc_install/petsc_knl_intel
export PETSC_ARCH=""
export CRAY_ROOTFS=DSL
export CRAYPE_LINK_TYPE=dynamic
export LD_LIBRARY_PATH=${PYTHON_DIR}/lib:${LD_LIBRARY_PATH}

# For perl language warnings
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
module list