#!/bin/bash

if [[ -z "${BASE_DIR}" ]]; then
    BASE_DIR=${HOME}/MPAS/Components
fi

if [[ -z "${EXE_DIR}" ]]; then
    EXE_DIR=${HOME}/MPAS/Components
fi

if [[ -z "${SCRIPT_DIR}" ]]; then
    SCRIPT_DIR=`pwd`
fi

LOG_FILE=$BASE_DIR/nightly_log_coriAlbany.txt
eval "env TEST_DIRECTORY=$BASE_DIR SCRIPT_DIRECTORY=$BASE_DIR ctest -VV -S $SCRIPT_DIR/components/ctest_nightly_albany.cmake" > $LOG_FILE 2>&1