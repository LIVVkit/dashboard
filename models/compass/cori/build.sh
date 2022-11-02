#!/bin/bash
# Build COMPASS conda environment

# Should get the following env variables from the external script:
# - COMPASS_MPI
# - TEST_DIR_RUN
# - REF_DIR
# - TEST_ROOT

export CONDA_DIR=$SCRATCH/.conda

# for env in $(/bin/ls $CONDA_DIR/envs)
for env in $(find ${CONDA_DIR}/envs -name "*compass*")
do
    echo REMOVE $(basename ${env})
    $SCRATCH/.conda/bin/conda env remove -n $(basename ${env})
done

./conda/configure_compass_env.py \
    --conda $SCRATCH/.conda \
    --machine cori-knl \
    --env_only || exit

# Find and load conda environment
LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
source $LOAD_COMPASS_SCRIPT

# Temporary install so summary e-mails can be sent by this environment
$CONDA_DIR/condabin/mamba install -c conda-forge gitpython svn ruamel.yaml -y
pip install svn pysvn

# Clean up old logs
rm -f $TEST_DIR_RUN/case_outputs/*.log

compass suite \
--core landice \
--test_suite full_integration \
--setup \
--config_file compass/machines/cori-haswell.cfg \
--machine cori-haswell \
--work_dir $TEST_DIR_RUN \
--baseline_dir $REF_DIR \
--mpas_model $TEST_ROOT/E3SM/components/mpas-albany-landice \
--clean || exit