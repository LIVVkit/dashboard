#!/bin/bash

pushd MPAS-Model || exit
source /global/homes/m/mperego/cori_modules.sh
module unload craype-hugepages2M
module load darshan
module load python

# note this version has no netcdf support
# PIO=/global/homes/m/mperego/piscees/mpas/TPL/pio/pio-build/install-22-may-2020
PIO=/global/u2/m/mek/MPAS/Components/build/PIOInstall

# source /global/homes/m/mperego/albany/albany-build/install-sfad24-10-apr-2020/export_albany.in
source /global/u2/m/mek/MPAS/Components/build/AlbanyInstall/export_albany.in
#module swap craype/2.5.18
#module swap gcc/8.2.0

export CRAYPE_LINK_TYPE=STATIC

MPAS_EXTERNAL_LIBS="$ALBANY_LINK_LIBS -lstdc++"

CORE=landice

make clean gnu-nersc ALBANY=true USE_PIO2=true CORE=$CORE PIO=$PIO MPAS_EXTERNAL_LIBS="$MPAS_EXTERNAL_LIBS" DEBUG=true EXE_NAME=landice_model_feb_6_2020

TESTDIR=$SCRATCH/MPAS/mali_test_run
popd || exit
pushd MPAS-Model/testing_and_setup/compass || exit
$HOME/.conda/envs/compass_py3.7/bin/python setup_testcase.py -f $TESTDIR/general.config.landice --work_dir=$TESTDIR -m $TESTDIR/srun.xml -n 22
$HOME/.conda/envs/compass_py3.7/bin/python setup_testcase.py -f $TESTDIR/general.config.landice --work_dir=$TESTDIR -m $TESTDIR/srun.xml -n 23
$HOME/.conda/envs/compass_py3.7/bin/python setup_testcase.py -f $TESTDIR/general.config.landice --work_dir=$TESTDIR -m $TESTDIR/srun.xml -n 24
$HOME/.conda/envs/compass_py3.7/bin/python setup_testcase.py -f $TESTDIR/general.config.landice --work_dir=$TESTDIR -m $TESTDIR/srun.xml -n 25
$HOME/.conda/envs/compass_py3.7/bin/python setup_testcase.py -f $TESTDIR/general.config.landice --work_dir=$TESTDIR -m $TESTDIR/srun.xml -n 29
