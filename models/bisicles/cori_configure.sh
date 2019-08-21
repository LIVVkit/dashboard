#!/usr/bin/env bash

pushd Chombo || exit
svn cleanup . --remove-unversioned
svn up
cd lib/mk || exit
ln -s local/Make.defs.cori.knl.intel Make.defs.local
popd || exit

pushd BISICLES || exit
svn cleanup . --remove-unversioned
svn up
popd || exit
