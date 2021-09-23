#!/bin/bash

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR=${CSCRATCH}/MPAS/Components
fi

if [[ -z "${EXE_DIR}" ]]; then
    EXE_DIR=${CSCRATCH}/MPAS/Components
fi

if [[ -z "${CMAKE_SCRIPTS}" ]]; then
    CMAKE_SCRIPTS=`pwd`
fi
if [[ -z "${SCRIPT_DIR}" ]]; then
    SCRIPT_DIR=`pwd`
fi

LOG_FILE=$BASE_DIR/nightly_log_coriTrilinos.txt
# module unload cmake
# module load cmake/3.18.2
eval "env TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/ctest_nightly_trilinos.cmake" > $LOG_FILE 2>&1
# module unload cmake
# module load cmake/3.14.4
