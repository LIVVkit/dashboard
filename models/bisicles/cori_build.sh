#!/usr/bin/env bash
if [ "$(readlink -- "BISICLES")" = "BISICLES_release" ]
then
    source $HOME/dashboard/nightly_scripts/bisicles_modules_old.sh
else
    source $HOME/dashboard/nightly_scripts/bisicles_modules.sh
fi


# pushd BISICLES/CISM-interface/exec2D || exit
# pushd BISICLES/code/exec2D

# Simple unit tests
# pushd BISICLES/code/test
# make -j4 all MPI=TRUE USE_PETSC=TRUE DEBUG=FALSE OPT=TRUE

# Regression tests
for testname in twistyStream benchmark ASE-control
do
    echo "####################### MAKE ${testname} ###########################"
    pushd BISICLES/code/regression/$testname
    make -j4 all MPI=TRUE USE_PETSC=TRUE DEBUG=FALSE OPT=TRUE
    popd
done
