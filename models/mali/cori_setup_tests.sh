#!/bin/bash

source /global/homes/m/mperego/cori_modules.sh
module unload craype-hugepages2M
module load darshan

TESTDIR=$SCRATCH/MPAS/mali_reg_suite
pyexe=$HOME/.conda/envs/compass_py3.7/bin/python
config=$TESTDIR/general.config.landice
srunfile=$TESTDIR/srun.xml

pushd MPAS-Model/testing_and_setup/compass || exit
# Individual test setup
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 22
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 23
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 24
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 25
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 29

# Setup regression suite
$pyexe manage_regression_suite.py \
--test_suite landice/regression_suites/ho_integration_test_suite.xml \
--config_file $config \
--work_dir $TESTDIR \
--model_runtime $srunfile \
--clean \
--setup