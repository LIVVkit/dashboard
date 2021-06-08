#!/bin/bash
# This is run on cori04 nightly

# Setup modules and environment variables
export CTEST_CONFIG_DIR=$HOME/dashboard/nightly_scripts/
export SCRIPT_DIR=$HOME/dashboard/nightly_scripts/bisicles
export BASE_DIR=$CSCRATCH/bisicles
export COMP_DIR=$BASE_DIR/Components

export CTEST_DO_SUBMIT=ON

pushd $SCRIPT_DIR || exit

# source $CTEST_CONFIG_DIR/bisicles_modules.sh >& modules.log
# Build required components for BISICLES (no tests run on these)

PY_EXE=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
TESTDIR=/global/homes/m/mek/dashboard

# Chombo, BISICLES order (e.g. rt is Chombo Release BISICLES Trunk)
for profile in rr tt rt tr
do
    # Now perform BISICLES build
    printf "Build BISICLES $profile\n"

    pushd $TESTDIR || exit
    if [ ${CTEST_DO_SUBMIT} == "ON" ]; then
        $PY_EXE worker.py profiles/build_bisicles_${profile}_cori.yaml --site cori-knl -S
    else
        $PY_EXE worker.py profiles/build_bisicles_${profile}_cori.yaml --site cori-knl
    fi

    # Now submit BISICLES Tests to queue
    popd
    pushd $SCRIPT_DIR || exit
    sbatch --wait bisicles_tests.sbatch
    # Should only be one LastTest_*.log, copy that out so we can do separate text
    # processing to create a summary e-mail that's more clear than the CDash one
    cp $BASE_DIR/Testing/Temporary/LastTest_*.log $BASE_DIR/test_logs/test_${profile}_`date +"%Y-%m-%d"`.log
    popd

done

pushd $TESTDIR
if [ $CTEST_DO_SUBMIT == "ON" ];then
    $pyexe summarise.py --model bisicles -S -C
else
    $pyexe summarise.py --model bisicles
fi