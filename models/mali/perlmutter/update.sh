#!/usr/bin/env bash

pushd MPAS-Model || exit
git clean -fx
git pull --ff-only
git rev-parse HEAD
popd || exit
