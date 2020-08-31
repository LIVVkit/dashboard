#!/bin/bash
# This is run on cori04 nightly

# Setup modules and environment variables
export SCRIPT_DIR=/global/homes/m/mek/nightly_test_scripts/mali
export BASE_DIR=/global/homes/m/mek/MPAS/Components
export EXE_DIR=/global/homes/m/mek/MPAS/Components
export CTEST_DO_SUBMIT=ON
export CTEST_CONFIG_DIR=$HOME/nightly_test_scripts/

pushd $SCRIPT_DIR || exit

source /global/homes/m/mperego/cori_modules.sh >& modules.log
module unload craype-hugepages2M
module load darshan

export CRAYPE_LINK_TYPE=STATIC

printf "CLEAN UP \n$BASE_DIR/build\n$BASE_DIR/src\n"
rm -rf $BASE_DIR/build
rm -rf $BASE_DIR/src

# Build required components for MALI (no tests run on these)
printf "Build components\n"
printf "\tTrilinos\n"
bash ${SCRIPT_DIR}/components/cron_script_trilinos_cori.sh
printf "\tAlbany\n"
bash ${SCRIPT_DIR}/components/cron_script_albany_cori.sh
printf "\tPIO\n"
bash ${SCRIPT_DIR}/components/cron_script_pio_cori.sh

# Now perform MALI build
printf "Build MALI\n"
PY_EXE=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
TESTDIR=/global/homes/m/mek/dashboard

pushd $TESTDIR || exit
$PY_EXE worker.py profiles/build_mali_cori.yaml --site cori-knl -S

# Now submit MALI Tests to queue
popd
pushd $SCRIPT_DIR || exit
sbatch mali_tests.sbatch