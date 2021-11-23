#!/usr/bin/env bash

# Repository locations
# svn co https://anag-repo.lbl.gov/svn/BISICLES/public/release/current BISICLES_release
# svn co https://anag-repo.lbl.gov/svn/BISICLES/public/trunk BISICLES_trunk
# svn co https://anag-repo.lbl.gov/svn/Chombo/release/3.2 Chombo_release
# svn co https://anag-repo.lbl.gov/svn/Chombo/trunk Chombo_trunk

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

if [ BIS_BUILD == "release" ];then
    source $HOME/dashboard/nightly_scripts/bisicles_modules_old.sh
else
    source $HOME/dashboard/nightly_scripts/bisicles_modules.sh
fi
export BISICLES_HOME=$CSCRATCH/bisicles
cd $BISICLES_HOME
rm -f Chombo BISICLES

ln -sf Chombo_${CH_BUILD} Chombo
ln -sf BISICLES_${BIS_BUILD} BISICLES

pushd Chombo || exit
svn cleanup && svn cleanup . --remove-unversioned || exit
svn up || exit
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
svn cleanup && svn cleanup . --remove-unversioned || exit
svn up
popd || exit
