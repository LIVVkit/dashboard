#!/bin/bash
# This is run on cori04 nightly

# Setup modules and environment variables
export TEST_ROOT=$CSCRATCH
export NIGHTLY_SCRIPT_DIR=/global/homes/m/mek/dashboard/nightly_scripts/mali
export BASE_DIR=/global/homes/m/mek/MPAS/Components
export EXE_DIR=/global/homes/m/mek/MPAS/Components
export CTEST_DO_SUBMIT=ON
export CTEST_CONFIG_DIR=$HOME/dashboard/nightly_scripts/

pushd $NIGHTLY_SCRIPT_DIR || exit

# source /global/homes/m/mperego/cori_modules.sh >& modules.log
source $CTEST_CONFIG_DIR/mali_modules.sh >& modules.log
module unload craype-hugepages2M
module load darshan

export CRAYPE_LINK_TYPE=STATIC

printf "CLEAN UP \n$BASE_DIR/build\n$BASE_DIR/src\n"
rm -rf $BASE_DIR/build
rm -rf $BASE_DIR/src

# Build required components for MALI (no tests run on these)
printf "Build components\n"
printf "\tTrilinos\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_trilinos_cori.sh
printf "\tAlbany\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_albany_cori.sh
printf "\tPIO\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_pio_cori.sh

# Now perform MALI build
printf "Build MALI\n"
PY_EXE=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
DASH_DIR=/global/homes/m/mek/dashboard

pushd $DASH_DIR || exit
$PY_EXE worker.py profiles/build_mali_cori.yaml --site cori-knl -S || exit

# Now submit MALI Tests to queue
popd
pushd $NIGHTLY_SCRIPT_DIR || exit
sbatch --wait mali_tests.sbatch
pushd $DASH_DIR || exit

$PY_EXE summarise.py -S -C

# Archive the regression suite
TEST_DIR_RUN=$TEST_ROOT/MPAS/MALI_Test
TEST_DIR_ARCH=$TEST_ROOT/MPAS/MALI_`date +"%Y-%m-%d"`
cp -R $TEST_DIR_RUN $TEST_DIR_ARCH

chgrp -R piscees $CSCRATCH/MPAS
