#!/bin/bash

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR=${CSCRATCH}/MPAS/Components
fi

if [[ -z "${EXE_DIR}" ]]; then
    EXE_DIR=${CSCRATCH}/MPAS/Components
fi

if [[ -z "${SCRIPT_DIR}" ]]; then
    SCRIPT_DIR=`pwd`
fi

# Find the gcc library directory
LOG_FILE=$BASE_DIR/nightly_log_coriAlbany.txt
# For now on Cori, Albany doesn't build with new cmake versions (>3.14.4) not sure
# what is happening here...so swap the module out and build, then swap back
module swap cmake cmake/3.14.4
eval "env TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/ctest_nightly_albany.cmake" > $LOG_FILE 2>&1
module swap cmake/3.14.4 cmake/3.21.3