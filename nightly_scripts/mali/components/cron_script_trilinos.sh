#!/bin/bash

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR=${SCRATCH}/MPAS/Components
fi

if [[ -z "${EXE_DIR}" ]]; then
    EXE_DIR=${SCRATCH}/MPAS/Components
fi

if [[ -z "${CMAKE_SCRIPTS}" ]]; then
    CMAKE_SCRIPTS=`pwd`
fi
if [[ -z "${SCRIPT_DIR}" ]]; then
    SCRIPT_DIR=`pwd`
fi
if [[ -z "${NERSC_HOST}" ]]; then
    MACHINE_HOST=$(hostname)
else
    MACHINE_HOST=${NERSC_HOST}
fi
LOG_FILE=$BASE_DIR/nightly_log_${MACHINE_HOST}_Trilinos.txt
eval "env TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/${MACHINE_HOST}/ctest_nightly_trilinos.cmake" > $LOG_FILE 2>&1
