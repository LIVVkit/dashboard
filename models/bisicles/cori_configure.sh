#!/usr/bin/env bash
BIS_BUILD=$1
CH_BUILD=$2
if [ -z "${BIS_BUILD}" ]
then
    BIS_BUILD="release"
fi

if [ -z "${CH_BUILD}" ]
then
    CH_BUILD="release"
fi

source $HOME/dashboard/nightly_scripts/bisicles_modules.sh
export BISICLES_HOME=$CSCRATCH/bisicles
cd $BISICLES_HOME
rm -f Chombo BISICLES

ln -sf Chombo_${CH_BUILD} Chombo
ln -sf BISICLES_${BIS_BUILD} BISICLES

pushd Chombo || exit
svn cleanup . --remove-unversioned
svn up
pushd lib/mk || exit
if [ $BIS_BUILD = "release" ]
then
    ln -sf $BISICLES_HOME/Make.defs.local.2 Make.defs.local
else
    ln -sf $BISICLES_HOME/Make.defs.local.3 Make.defs.local
fi

# ln -s local/Make.defs.cori.knl.intel Make.defs.local
popd && popd || exit

pushd BISICLES || exit
svn cleanup . --remove-unversioned
svn up
popd || exit
