#!/usr/bin/env bash
if [ ! -d compass ]; then
    git clone https://github.com/MPAS-Dev/compass.git || exit
    pushd compass
    git submodule update --init --recursive
    popd
fi
pushd compass || exit
git clean -fx || exit
git submodule update --init --recursive
git pull --recurse-submodules --ff-only || exit
popd || exit