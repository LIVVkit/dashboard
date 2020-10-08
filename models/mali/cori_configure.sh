#!/usr/bin/env bash
if [ ! -d  MPAS-Model ]; then
    git clone -b landice/develop git@github.com:MPAS-Dev/MPAS-Model.git
fi

pushd MPAS-Model || exit
git clean -fx
git pull --ff-only
popd || exit
