
# Setup conda
export CONDA_ENV=/ccs/home/mkelleher/.local/share/virtualenvs/titan/dashboard
export PY_EXE=${CONDA_ENV}/bin/python3
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

if [[ -z "${NERSC_HOST}" ]]; then
    export MACHINE_HOST=$(hostname -d | awk -F\. '{print $1}')
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
elif [[ $MACHINE_HOST == 'frontier' ]]; then
    # source /ccs/proj/atm112/conda_envs/load_latest_triset.sh
    export SITE=${MACHINE_HOST}
    export CTEST_DO_SUBMIT=ON
else
    export CTEST_DO_SUBMIT=OFF
    export SITE=${MACHINE_HOST}
fi

if [[ -f ${CONDA_ROOT}/etc/profile.d/conda.sh ]]; then
    source $CONDA_ROOT/etc/profile.d/conda.sh
    conda activate $CONDA_ENV
fi

echo "RUNNING TESTS ON ${MACHINE_HOST} (${SITE})"

# Setup modules and environment variables
export PERFORM_TESTS=ON

export TEST_ROOT=/lustre/orion/atm112/proj-shared/triton_nightly_testing

export TRISET_DIR=${TEST_ROOT}/build/triset
export TRITON_SRC_DIR=${TEST_ROOT}/build/triton
export TRITON_KOKKOS_DIR=${TEST_ROOT}/build/triton_kokkos

export DASH_DIR=${HOME}/dashboard
export CTEST_CONFIG_DIR=${DASH_DIR}/nightly_scripts
export NIGHTLY_SCRIPT_DIR=${CTEST_CONFIG_DIR}/triton
export BASE_DIR=$TEST_ROOT/Components
export EXE_DIR=$TEST_ROOT/Components
export INPUT_DIR=/lustre/orion/atm112/proj-shared/mkelleher/inputdata
# Reference, testing, and archive directories for COMPASS
export OUT_ROOT=$TEST_ROOT/TestOutput
export REF_DIR=$TEST_ROOT/baselines
export TEST_DIR_RUN=$OUT_ROOT
export TEST_DIR_ARCH=$OUT_ROOT/TRITON_`date +"%Y-%m-%d"`
