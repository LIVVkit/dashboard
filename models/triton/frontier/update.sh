#!/usr/bin/env bash

pushd triton || exit
git clean -fx
git pull --ff-only
git rev-parse HEAD
popd || exit
