#!/bin/bash
CONDA_ENV=/global/common/software/piscees/mali/conda/compass
COMPASS_DIR=$CSCRATCH/MPAS/MPAS-Model/testing_and_setup/compass

source $HOME/dashboard/nightly_scripts/mali_modules.sh > modules.log

source /usr/common/software/python/3.8-anaconda-2020.11/etc/profile.d/conda.sh
conda activate ${CONDA_ENV}

TESTDIR=$CSCRATCH/MPAS/MALI_Test
pyexe=${CONDA_ENV}/bin/python3
config=$TESTDIR/general.config.landice

srunfile=$COMPASS_DIR/runtime_definitions/srun.xml

pushd $COMPASS_DIR || exit

# Setup regression suite
rm -f $TESTDIR/case_outputs/*
rm -f $TESTDIR/manage_regression_suite.py.out

$pyexe manage_regression_suite.py \
--verbose \
--test_suite landice/regression_suites/combined_integration_test_suite.xml \
--baseline_dir $CSCRATCH/MPAS/MALI_Reference \
--config_file $config \
--work_dir $TESTDIR \
--model_runtime $srunfile \
--clean \
--setup || cat $TESTDIR/manage_regression_suite.py.out; exit

# Make a copy of test suite XML in the test directory for later ref
# Use a standard name so it can be referenced in summarise.py to send email
cp landice/regression_suites/combined_integration_test_suite.xml $TESTDIR/regression.xml
