#!/bin/bash
pushd ${TRISET_DIR}/triset || exit
$PY_EXE triton_test.py \
    --input_dir $INPUT_DIR \
    --nnodes 1 \
    --config templates/cfg/case01.cfg \
    --name case01_nightly_build_only \
    --output_root $OUT_ROOT \
    --force \
    --mach frontier \
    --project ATM112 \
    --wallclock 5 \
    --src ${TRITON_SRC_DIR} \
    --platform hip \
    --no-run || exit

cat $OUT_ROOT/case01_nightly_build_only/bld/build.log || exit

chgrp -R atm112 .
