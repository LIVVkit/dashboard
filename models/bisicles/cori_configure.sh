#!/usr/bin/env bash
source $HOME/nightly_test_scripts/bisicles_modules.sh
export BISICLES_HOME=$CSCRATCH/bisicles
cd $BISICLES_HOME
pushd Chombo || exit
svn cleanup . --remove-unversioned
svn up
pushd lib/mk || exit
ln -sf $BISICLES_HOME/Make.defs.local Make.defs.local
# ln -s local/Make.defs.cori.knl.intel Make.defs.local
popd && popd || exit

pushd BISICLES || exit
svn cleanup . --remove-unversioned
svn up
popd || exit
