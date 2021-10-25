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
export CTEST_CONFIG_DIR=$HOME/dashboard/nightly_scripts/
export DASH_DIR=/global/homes/m/mek/dashboard

# Testing directories for New COMPASS
BASE_DIR_NEW=$TEST_ROOT/NewTests/MALI_Reference
TEST_DIR_RUN_NEW=$TEST_ROOT/NewTests/MALI_Test
TEST_DIR_ARCH_NEW=$TEST_ROOT/NewTests/MALI_`date +"%Y-%m-%d"`

# Testing directories for Old COMPASS
TEST_DIR_RUN=$TEST_ROOT/MALI_Test
TEST_DIR_ARCH=$TEST_ROOT/MALI_`date +"%Y-%m-%d"`

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
else
    $PY_EXE worker.py profiles/build_mali_cori.yaml --site cori-knl || exit
fi

# Setup new COMPASS tests
pushd $TEST_ROOT/compass
COMPASS_ENV=dev_compass_1.0.0_openmpi
if [ -d $CSCRATCH/.conda/envs/$COMPASS_ENV ]; then
    # Remove old compass env if it exists already (conflicts happened once)
    # when updating...caused environment solving to hang
    $CSCRATCH/.conda/bin/conda env remove -n $COMPASS_ENV
fi
# Also check for the temp env
if [ -d $CSCRATCH/.conda/envs/temp_compass_install ]; then
    $CSCRATCH/.conda/bin/conda env remove -n temp_compass_install
fi

./conda/configure_compass_env.py --conda $CSCRATCH/.conda -c intel -m cori-knl --mpi openmpi || exit

# Load conda environment
# source $TEST_ROOT/compass/load_dev_compass_1.0.0_cori-knl_intel_openmpi.sh
source $TEST_ROOT/compass/load_${COMPASS_ENV}.sh

# Temporary install so summary e-mails can be sent by this environment
conda install -c conda-forge gitpython svn ruamel.yaml -y
pip install svn pysvn

# Clean up old logs
rm -f $TEST_DIR_RUN_NEW/case_outputs/*.log

compass suite \
--core landice \
--test_suite full_integration \
--setup \
--machine cori-knl \
--work_dir $TEST_DIR_RUN_NEW \
--baseline_dir $BASE_DIR_NEW \
--mpas_model $TEST_ROOT/E3SM/components/mpas-albany-landice \
--clean || exit

# Now submit MALI Tests to queue
popd
pushd $NIGHTLY_SCRIPT_DIR || exit
sbatch --wait mali_tests_new.sbatch
sbatch --wait mali_tests.sbatch
pushd $DASH_DIR || exit

if [ ${CTEST_DO_SUBMIT} == "ON" ]; then
    $CONDA_PREFIX/bin/python summarise.py --model mali -S -C
    $CONDA_PREFIX/bin/python summarise.py --model newmali -S -C
else
    $CONDA_PREFIX/bin/python summarise.py --model mali
    $CONDA_PREFIX/bin/python summarise.py --model newmali
fi

# Archive the OLD regression suite
# Make a backup copy of an already existing archive. Why this happens? Dunno yet.
if [ -e $TEST_DIR_ARCH ];then
    mv $TEST_DIR_ARCH ${TEST_DIR_ARCH}_`date +"%s"`
fi
cp -R $TEST_DIR_RUN $TEST_DIR_ARCH

# Archive the NEW regression suite
# Make a backup copy of an already existing archive. Why this happens? Dunno yet.
if [ -e $TEST_DIR_ARCH_NEW ];then
    mv $TEST_DIR_ARCH_NEW ${TEST_DIR_ARCH_NEW}_`date +"%s"`
fi
cp -R $TEST_DIR_RUN_NEW $TEST_DIR_ARCH_NEW

chgrp -R piscees $CSCRATCH/MPAS

REF_DIR=$TEST_ROOT/MALI_Reference/landice
OUTDIR=/project/projectdirs/piscees/www/mek/vv_`date '+%Y_%m_%d'`
LATEST_LINK=/project/projectdirs/piscees/www/mek/latest
$HOME/.conda/envs/livv/bin/livv -v $TEST_DIR_ARCH/landice $REF_DIR -o $OUTDIR -p 32 || exit
chmod -R 0755 $OUTDIR
rm -f $LATEST_LINK
ln -sf $OUTDIR $LATEST_LINK
chmod -R 0755 $LATEST_LINK

echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
echo "LIVV Results available at: https://portal.nersc.gov/project/piscees/mek/vv_`date '+%Y_%m_%d'`"
