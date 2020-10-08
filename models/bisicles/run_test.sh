#!/usr/bin/env bash
echo "Hostname: "`hostname`
# pushd BISICLES/CISM-interface/exec2D || exit
pushd BISICLES/code/exec2D || exit
driver="$(find . -type f -name "driver2d.*.ex")"
eval "srun -n 1 ${driver}" "$1"
