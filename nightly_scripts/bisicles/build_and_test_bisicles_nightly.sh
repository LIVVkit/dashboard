#!/bin/bash
# This is run on cori04 nightly

# Setup modules and environment variables
export CTEST_CONFIG_DIR=$HOME/nightly_test_scripts/
export SCRIPT_DIR=$HOME/nightly_test_scripts/bisicles
export BASE_DIR=$CSCRATCH/bisicles
export COMP_DIR=$BASE_DIR/Components

export CTEST_DO_SUBMIT=ON

pushd $SCRIPT_DIR || exit

# source $CTEST_CONFIG_DIR/bisicles_modules.sh >& modules.log
# Build required components for MALI (no tests run on these)

# Now perform BISICLES build
printf "Build BISICLES\n"
PY_EXE=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
TESTDIR=/global/homes/m/mek/dashboard

pushd $TESTDIR || exit
$PY_EXE worker.py profiles/build_bisicles_cori.yaml --site cori-knl -S

# Now submit MALI Tests to queue
popd
pushd $SCRIPT_DIR || exit
sbatch bisicles_tests.sbatch