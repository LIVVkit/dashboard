#!/usr/bin/env bash
if [ ! -d  MPAS-Model ]; then
    git clone -b landice/develop git@github.com:MPAS-Dev/MPAS-Model.git || exit
fi

pushd MPAS-Model || exit
git clean -fx || exit
git pull --ff-only || exit
popd || exit

if [ ! -d compass ]; then
    git clone https://github.com/MPAS-Dev/compass.git || exit
fi
pushd compass || exit
git clean -fx || exit
git pull --ff-only || exit
popd || exit
