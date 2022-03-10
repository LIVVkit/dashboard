#!/bin/bash
# Build COMPASS conda environment

# Should get the following env variables from the external script:
# - COMPASS_MPI
# - TEST_DIR_RUN_NEW
# - BASE_DIR_NEW
# - TEST_ROOT

export COMPASS_ENV=dev_compass_1.0.0_${COMPASS_MPI}
export ENV_NAME=dev_compass_1.0.0
if [ -d $CSCRATCH/.conda/envs/$COMPASS_ENV ]; then
    # Remove old compass env if it exists already (conflicts happened once)
    # when updating...caused environment solving to hang
    $CSCRATCH/.conda/bin/conda env remove -n $COMPASS_ENV
fi

# Also check for a directory with just the name (no mpi version attached)
if [ -d $CSCRATCH/.conda/envs/$ENV_NAME ]; then
    $CSCRATCH/.conda/bin/conda env remove -n $ENV_NAME
fi

# Also check for the temp env
if [ -d $CSCRATCH/.conda/envs/temp_compass_install ]; then
    $CSCRATCH/.conda/bin/conda env remove -n temp_compass_install
fi

./conda/configure_compass_env.py --conda $CSCRATCH/.conda -c intel -m cori-knl --mpi $COMPASS_MPI || exit

# Find and load conda environment
LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
source $LOAD_COMPASS_SCRIPT

# Temporary install so summary e-mails can be sent by this environment
conda install -c conda-forge gitpython svn ruamel.yaml -y
pip install svn pysvn

# Clean up old logs
rm -f $TEST_DIR_RUN_NEW/case_outputs/*.log

compass suite \
--core landice \
--test_suite full_integration \
--setup \
--config_file compass/machines/cori-knl.cfg \
--work_dir $TEST_DIR_RUN_NEW \
--baseline_dir $BASE_DIR_NEW \
--mpas_model $TEST_ROOT/E3SM/components/mpas-albany-landice \
--clean || exit

# --machine cori-knl \