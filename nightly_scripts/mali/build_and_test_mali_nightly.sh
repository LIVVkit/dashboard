#!/bin/bash
# This is run on cori04 nightly

# Setup conda
export CONDA_ENV=/global/common/software/piscees/mali/conda/pyctest
export PY_EXE=${CONDA_ENV}/bin/python3

if [[ -z "${NERSC_HOST}" ]]; then
    HOST=$(hostname)
else
    HOST=${NERSC_HOST}
fi

if [[ $HOST == 'cori' ]]; then
    source /usr/common/software/python/3.8-anaconda-2020.11/etc/profile.d/conda.sh
    export CTEST_DO_SUBMIT=ON
    export SITE=cori-knl
fi
if [[ $HOST == 'perlmutter' ]]; then
    source /global/common/software/nersc/pm-2022q2/sw/python/3.9-anaconda-2021.11/etc/profile.d/conda.sh
    export CTEST_DO_SUBMIT=OFF
    export SITE=pm-cpu
fi
conda activate $CONDA_ENV

# Setup modules and environment variables
export PERFORM_TESTS=ON

export TEST_ROOT=$SCRATCH/MPAS
export DASH_DIR=${HOME}/dashboard
export CTEST_CONFIG_DIR=${DASH_DIR}/nightly_scripts
export NIGHTLY_SCRIPT_DIR=${CTEST_CONFIG_DIR}/mali
export BASE_DIR=$TEST_ROOT/Components
export EXE_DIR=$TEST_ROOT/Components

# Reference, testing, and archive directories for COMPASS
export OUT_ROOT=$TEST_ROOT/TestOutput
export REF_DIR=$OUT_ROOT/MALI_Reference
export TEST_DIR_RUN=$OUT_ROOT/MALI_Test
export TEST_DIR_ARCH=$OUT_ROOT/MALI_`date +"%Y-%m-%d"`


for DTEST in ${BASE_DIR} ${EXE_DIR} ${OUT_ROOT}
do
    if [[ ! -d ${DTEST} ]]
    then
        echo "CREATING ${DTEST}"
        mkdir -p ${DTEST}
    fi
done


pushd $NIGHTLY_SCRIPT_DIR || exit

source $CTEST_CONFIG_DIR/mali_modules_${HOST}.sh >& modules_${HOST}.log

printf "CLEAN UP \n$BASE_DIR/build\n$BASE_DIR/src\n"
rm -rf $BASE_DIR/build
rm -rf $BASE_DIR/src

# Build required components for MALI (no tests run on these)
printf "Build components\n"
printf "\tTrilinos\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_trilinos.sh
printf "\tAlbany\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_albany.sh
printf "\tPIO\n"
bash ${NIGHTLY_SCRIPT_DIR}/components/cron_script_pio.sh

# Now perform MALI build
printf "Build MALI\n"

pushd $DASH_DIR || exit
if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    $PY_EXE worker.py profiles/${HOST}/build_mali.yaml --site ${SITE} -S || exit
    $PY_EXE worker.py profiles/${HOST}/build_compass.yaml --site ${SITE} -S || exit
else
    $PY_EXE worker.py profiles/${HOST}/build_mali.yaml --site ${SITE} || exit
    $PY_EXE worker.py profiles/${HOST}/build_compass.yaml --site ${SITE} || exit
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

    chgrp -R piscees ${TEST_ROOT}

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