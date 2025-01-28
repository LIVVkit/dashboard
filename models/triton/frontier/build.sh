#!/bin/bash
pushd triset/triset || exit
$PY_EXE triton_test.py \
    --input_dir $INPUT_DIR \
    --nnodes 1 \
    --config templates/cfg/case01.cfg \
    --name CASE01_NIGHTLY \
    --output_root $OUT_ROOT \
    --force \
    --mach frontier \
    --project ATM112 \
    --wallclock 5 \
    --src $TEST_ROOT/triton \
    --platform hip \
    --no-run

# cat $OUT_ROOT/CASE01_NIGHTLY/bld/build.log

chgrp -R atm112 .
