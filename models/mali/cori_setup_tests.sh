#!/bin/bash

source $HOME/dashboard/nightly_scripts/mali_modules.sh > modules.log
module unload craype-hugepages2M
module load darshan

TESTDIR=$CSCRATCH/MPAS/MALI_Test
pyexe=$HOME/.conda/envs/compass_py3.7/bin/python
config=$TESTDIR/general.config.landice
# srunfile=$TESTDIR/srun.xml
srunfile=$CSCRATCH/MPAS/compass/runtime_definitions/srun.xml

pushd compass || exit
# Individual test setup
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 22
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 23
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 24
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 25
# $pyexe setup_testcase.py -f $config --work_dir=$TESTDIR -m $srunfile -n 29

# Setup regression suite
rm -f $TESTDIR/case_outputs/*

$pyexe manage_regression_suite.py \
--test_suite landice/regression_suites/combined_integration_test_suite.xml \
--baseline_dir $CSCRATCH/MPAS/MALI_Reference \
--config_file $config \
--work_dir $TESTDIR \
--model_runtime $srunfile \
--clean \
--setup || exit

# Make a copy of test suite XML in the test directory for later ref
# Use a standard name so it can be referenced in summarise.py to send email
cp landice/regression_suites/combined_integration_test_suite.xml $TESTDIR/regression.xml
