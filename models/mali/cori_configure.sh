#!/usr/bin/env bash

pushd MPAS-Model || exit
git clean -fx
git pull --ff-only
popd || exit