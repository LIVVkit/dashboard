#!/usr/bin/env bash

pushd BISICLES/CISM-interface/exec2D || exit
driver="$(find . -type f -name "driver2d.*.ex")"
eval "${driver}" "$1"
