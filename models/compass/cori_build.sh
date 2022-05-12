#!/bin/bash
# Build COMPASS conda environment

# Should get the following env variables from the external script:
# - COMPASS_MPI
# - TEST_DIR_RUN_NEW
# - BASE_DIR_NEW
# - TEST_ROOT

export CONDA_DIR=$CSCRATCH/.conda

for env in $(/bin/ls $CONDA_DIR/envs)
do
    echo REMOVE ${env}
    $CSCRATCH/.conda/bin/conda env remove -n ${env}
done

./conda/configure_compass_env.py \
    --conda $CSCRATCH/.conda \
    --compiler intel \
    --machine cori-knl \
    --mpi $COMPASS_MPI \
    --env_only || exit

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
--config_file compass/machines/cori-haswell.cfg \
--machine cori-haswell \
--work_dir $TEST_DIR_RUN_NEW \
--baseline_dir $BASE_DIR_NEW \
--mpas_model $TEST_ROOT/E3SM/components/mpas-albany-landice \
--clean || exit