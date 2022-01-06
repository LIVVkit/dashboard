#!/bin/bash
# Build COMPASS conda environment

# Should get the following env variables from the external script:
# - COMPASS_MPI
# - TEST_DIR_RUN_NEW
# - BASE_DIR_NEW
# - TEST_ROOT

pushd compass || exit
export COMPASS_ENV=dev_compass_1.0.0_${COMPASS_MPI}
if [ -d $CSCRATCH/.conda/envs/$COMPASS_ENV ]; then
    # Remove old compass env if it exists already (conflicts happened once)
    # when updating...caused environment solving to hang
    $CSCRATCH/.conda/bin/conda env remove -n $COMPASS_ENV
fi
# Also check for the temp env
if [ -d $CSCRATCH/.conda/envs/temp_compass_install ]; then
    $CSCRATCH/.conda/bin/conda env remove -n temp_compass_install
fi

./conda/configure_compass_env.py --conda $CSCRATCH/.conda -c intel -m cori-knl --mpi $COMPASS_MPI || exit

# Find and load conda environment
LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
source $LOAD_COMPASS_SCRIPT || exit

# source $TEST_ROOT/compass/load_dev_compass_1.0.0_cori-knl_intel_openmpi.sh
# source $TEST_ROOT/compass/load_${COMPASS_ENV}.sh

# Temporary install so summary e-mails can be sent by this environment
mamba install -c conda-forge gitpython svn ruamel.yaml -y || exit
pip install svn pysvn || exit

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