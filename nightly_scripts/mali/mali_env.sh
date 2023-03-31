
# Setup conda
export CONDA_ENV=/global/common/software/piscees/mali/conda/pyctest
export PY_EXE=${CONDA_ENV}/bin/python3

if [[ -z "${NERSC_HOST}" ]]; then
    export MACHINE_HOST=$(hostname)
else
    export MACHINE_HOST=${NERSC_HOST}
fi

if [[ $MACHINE_HOST == 'cori' ]]; then
    # export CONDA_ROOT=/usr/common/software/python/3.8-anaconda-2020.11
    export CONDA_ROOT=$SCRATCH/.conda
    export CTEST_DO_SUBMIT=ON
    export SITE=cori-knl
elif [[ $MACHINE_HOST == 'perlmutter' ]]; then
    # export CONDA_ROOT=/global/common/software/nersc/pm-2022q2/sw/python/3.9-anaconda-2021.11
    export CONDA_ROOT=$SCRATCH/.conda
    export CTEST_DO_SUBMIT=ON
    export SITE=pm-cpu
else
    export CTEST_DO_SUBMIT=OFF
    export SITE=${MACHINE_HOST}
fi

source $CONDA_ROOT/etc/profile.d/conda.sh
echo "RUNNING TESTS ON ${MACHINE_HOST} (${SITE})"
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