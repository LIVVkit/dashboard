#!/usr/bin/env bash
source $HOME/nightly_test_scripts/bisicles_modules.sh
# module load cray-hdf5-parallel
# module load cray-netcdf-hdf5parallel
# module load cray-shmem
# module load visit  # NOTE looks like it's only available via PrgEnv-gnu-VisIt
# module list

# export PETSC_DIR=/global/homes/m/madams/petsc_install/petsc-cori-knl-opt64-intel
export PETSC_DIR=/global/common/software/m1041/petsc_install/petsc_knl_intel
export PETSC_ARCH=

# pushd BISICLES/CISM-interface/exec2D || exit
pushd BISICLES/code/exec2D
make -j4 all MPI=TRUE USE_PETSC=TRUE DEBUG=FALSE OPT=TRUE
