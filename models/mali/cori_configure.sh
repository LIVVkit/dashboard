#!/usr/bin/env bash

pushd MPAS || exit
git clean -fx
git pull --ff-only
popd || exit
