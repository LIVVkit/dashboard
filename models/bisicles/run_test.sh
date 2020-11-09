#!/usr/bin/env bash
echo "Hostname: "`hostname`
source $HOME/dashboard/nightly_scripts/bisicles_modules.sh > modules.log
# pushd BISICLES/code/exec2D || exit
# driver="$(find . -type f -name "driver2d.*.ex")"
# eval "srun -n 1 ${driver}" "$1"

pushd BISICLES/code/test || exit
eval "srun -n 1 $1.Linux.64.CC.ftn.OPT.MPI.PETSC.ex"
mv pout.0 $1.log
cat $1.log || exit
! grep -E "fail" $1.log || exit