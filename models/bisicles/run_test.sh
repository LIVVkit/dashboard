#!/usr/bin/env bash
echo "Hostname: "`hostname`

# pushd BISICLES/code/exec2D || exit
# driver="$(find . -type f -name "driver2d.*.ex")"
# eval "srun -n 1 ${driver}" "$1"

pushd BISICLES/code/test || exit
eval "srun -n $1.Linux.64.CC.ftn.OPT.MPI.PETSC.ex"

if grep -E "pass" pout.0
then
    exit 1
else
    exit 0
fi