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
gcc_lib=$(dirname $(dirname $(which gcc)))/snos/lib64
echo "GCC LIB: $gcc_lib"
LOG_FILE=$BASE_DIR/nightly_log_coriAlbany.txt
eval "env LD_LIBRARY_PATH=$gcc_lib:$LD_LIBRARY_PATH TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/ctest_nightly_albany.cmake" > $LOG_FILE 2>&1