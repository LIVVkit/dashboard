#!/bin/bash
# This is run on scrontab nightly

source ${HOME}/dashboard/nightly_scripts/triton/triton_env.sh

for DTEST in ${OUT_ROOT}
do
    if [[ ! -d ${DTEST} ]]
    then
        echo "CREATING ${DTEST}"
        mkdir -p ${DTEST}
    fi
done

pushd $DASH_DIR || exit
if [ ${CTEST_DO_SUBMIT} == "ON" ]; then
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_triton.yaml --site ${SITE} -D TRITON -S || exit
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_triton_latest.yaml --site ${SITE} -D TRITON -S || exit
else
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_triton.yaml --site ${SITE} -D TRITON || exit
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_triton_latest.yaml --site ${SITE} -D TRITON || exit
fi

# Now submit MALI Tests to queue
# if [ ${PERFORM_TESTS} == "ON" ]; then
#     # Find and load conda environment
#     LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
#     echo "LOAD COMPASS ${LOAD_COMPASS_SCRIPT}"
#     source $LOAD_COMPASS_SCRIPT
#
#     popd
#     pushd $NIGHTLY_SCRIPT_DIR || exit
#     sbatch --wait mali_tests_${MACHINE_HOST}.sbatch
#     pushd $DASH_DIR || exit
#
#     if [ ${CTEST_DO_SUBMIT} == "ON" ]; then
#         $CONDA_PREFIX/bin/python summarise.py --model mali -S -C
#     else
#         $CONDA_PREFIX/bin/python summarise.py --model mali
#     fi
#
#     # Archive the regression suite
#     # Make a backup copy of an already existing archive. Why this happens? Dunno yet.
#     if [ -e $TEST_DIR_ARCH ];then
#         mv $TEST_DIR_ARCH ${TEST_DIR_ARCH}_`date +"%s"`
#     fi
#
#     cp -R $TEST_DIR_RUN $TEST_DIR_ARCH
#     chgrp -R piscees ${TEST_ROOT}
#     echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
# fi
