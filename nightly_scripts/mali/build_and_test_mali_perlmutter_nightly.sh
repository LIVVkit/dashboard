#!/bin/bash
# This is run on scrontab nightly

source ${HOME}/dashboard/nightly_scripts/mali/mali_env.sh

for DTEST in ${BASE_DIR} ${EXE_DIR} ${OUT_ROOT}
do
    if [[ ! -d ${DTEST} ]]
    then
        echo "CREATING ${DTEST}"
        mkdir -p ${DTEST}
    fi
done

pushd $NIGHTLY_SCRIPT_DIR || exit

# source $CTEST_CONFIG_DIR/mali_modules_${MACHINE_HOST}.sh >& modules_${MACHINE_HOST}.log

printf "CLEAN UP \n$BASE_DIR/build\n$BASE_DIR/src\n"
rm -rf $BASE_DIR/build
rm -rf $BASE_DIR/src

# Build required components for MALI (no tests run
# on these) then build MALI and COMPASS env
printf "SUBMIT BUILDS\n"
sbatch --wait build_software.sbatch

# Now submit MALI Tests to queue
if [ ${PERFORM_TESTS} == "ON" ]; then
    # Find and load conda environment
    LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
    echo "LOAD COMPASS ${LOAD_COMPASS_SCRIPT}"
    source $LOAD_COMPASS_SCRIPT

    popd
    pushd $NIGHTLY_SCRIPT_DIR || exit
    sbatch --wait mali_tests_${MACHINE_HOST}.sbatch
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
    chgrp -R piscees ${TEST_ROOT}
    echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
fi
