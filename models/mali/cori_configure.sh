#!/usr/bin/env bash
# if [ ! -d  MPAS-Model ]; then
#     git clone -b landice/develop git@github.com:MPAS-Dev/MPAS-Model.git || exit
# fi
export MODEL_ROOT=E3SM
if [ ! -d $MODEL_ROOT ]; then
    git clone -b develop git@github.com:MALI-Dev/E3SM.git
fi

pushd $MODEL_ROOT || exit
git clean -fx || exit
git pull --ff-only || exit
popd || exit

if [ ! -d compass ]; then
    git clone https://github.com/MPAS-Dev/compass.git || exit
    pushd compass
    git submodule update --init --recursive
    popd
fi
pushd compass || exit
git clean -fx || exit
git pull --ff-only --recurse || exit
popd || exit
