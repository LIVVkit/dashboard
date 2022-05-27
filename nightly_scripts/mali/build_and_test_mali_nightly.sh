#!/bin/bash
# This is run on cori04 nightly

# Setup conda
export CONDA_ENV=/global/common/software/piscees/mali/conda/pyctest
export PY_EXE=${CONDA_ENV}/bin/python3
source /usr/common/software/python/3.8-anaconda-2020.11/etc/profile.d/conda.sh
conda activate $CONDA_ENV

# Setup modules and environment variables
export TEST_ROOT=$CSCRATCH/MPAS
export NIGHTLY_SCRIPT_DIR=/global/homes/m/mek/dashboard/nightly_scripts/mali
export BASE_DIR=$TEST_ROOT/Components
export EXE_DIR=$TEST_ROOT/Components
export CTEST_DO_SUBMIT=ON
export PERFORM_TESTS=ON
export CTEST_CONFIG_DIR=$HOME/dashboard/nightly_scripts/
export DASH_DIR=/global/homes/m/mek/dashboard

# Reference, testing, and archive directories for COMPASS
export REF_DIR=$TEST_ROOT/TestOutput/MALI_Reference
export TEST_DIR_RUN=$TEST_ROOT/TestOutput/MALI_Test
export TEST_DIR_ARCH=$TEST_ROOT/TestOutput/MALI_`date +"%Y-%m-%d"`

pushd $NIGHTLY_SCRIPT_DIR || exit

source $CTEST_CONFIG_DIR/mali_modules.sh >& modules.log

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

pushd $DASH_DIR || exit
if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    $PY_EXE worker.py profiles/build_mali_cori.yaml --site cori-knl -S || exit
    $PY_EXE worker.py profiles/build_compass_cori.yaml --site cori-knl -S || exit
else
    $PY_EXE worker.py profiles/build_mali_cori.yaml --site cori-knl || exit
    $PY_EXE worker.py profiles/build_compass_cori.yaml --site cori-knl || exit
fi

# Now submit MALI Tests to queue
if [ ${PERFORM_TESTS} == "ON" ]; then
    # Find and load conda environment
    LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
    source $LOAD_COMPASS_SCRIPT

    popd
    pushd $NIGHTLY_SCRIPT_DIR || exit
    sbatch --wait mali_tests.sbatch
    pushd $DASH_DIR || exit

    if [ ${CTEST_DO_SUBMIT} == "ON" ]; then
        $CONDA_PREFIX/bin/python summarise.py --model mali -S -C
    else
        $CONDA_PREFIX/bin/python summarise.py --model mali
    fi

    # Archive the regression suite
    # Make a backup copy of an already existing archive. Why this happens? Dunno yet.
    if [ -e $TEST_DIR_ARCH ];then
        mv $TEST_DIR_ARCH ${TEST_DIR_ARCH}_`date +"%s"`
    fi
    cp -R $TEST_DIR_RUN $TEST_DIR_ARCH

    chgrp -R piscees $CSCRATCH/MPAS

    # REF_DIR=$TEST_ROOT//MALI_Reference/landice
    # OUTDIR=/project/projectdirs/piscees/www/mek/vv_`date '+%Y_%m_%d'`
    # LATEST_LINK=/project/projectdirs/piscees/www/mek/latest
    # $HOME/.conda/envs/livv/bin/livv -v $TEST_DIR_ARCH/landice $REF_DIR -o $OUTDIR -p 32 || exit
    # chmod -R 0755 $OUTDIR
    # rm -f $LATEST_LINK
    # ln -sf $OUTDIR $LATEST_LINK
    # chmod -R 0755 $LATEST_LINK

    echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
    # echo "LIVV Results available at: https://portal.nersc.gov/project/piscees/mek/vv_`date '+%Y_%m_%d'`"
fi