#!/usr/bin/env bash
export MODEL_ROOT=triton
if [ ! -d $MODEL_ROOT ]; then
    git clone https://code.ornl.gov/hydro/triton.git
fi

pushd $MODEL_ROOT || exit
git clean -fx || exit
git pull --ff-only || exit
popd || exit

export TSROOT=triset
if [ ! -d $TSROOT ]; then
    git clone git@code.ornl.gov:hydro/triset.git
fi

# pushd $TSROOT || exit
# git clean -fx || exit
# git pull --ff-only || exit
# popd || exit
