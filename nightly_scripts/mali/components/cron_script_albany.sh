#!/bin/bash

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR=${SCRATCH}/MPAS/Components
fi

if [[ -z "${EXE_DIR}" ]]; then
    EXE_DIR=${SCRATCH}/MPAS/Components
fi

if [[ -z "${SCRIPT_DIR}" ]]; then
    SCRIPT_DIR=`pwd`
fi

if [[ -z "${NERSC_HOST}" ]]; then
    HOST=$(hostname)
else
    HOST=${NERSC_HOST}
fi
LOG_FILE=$BASE_DIR/nightly_log_${HOST}_Albany.txt
# For now on Cori, Albany doesn't build with new cmake versions (>3.14.4) not sure
# what is happening here...so swap the module out and build, then swap back
# module swap cmake cmake/3.14.4
# cmake --version
eval "env TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/${HOST}/ctest_nightly_albany.cmake" > $LOG_FILE 2>&1
# module swap cmake/3.14.4 cmake/3.21.3