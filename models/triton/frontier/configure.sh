#!/usr/bin/env bash
if [ ! -d $TRITON_SRC_DIR ]; then
    git clone https://code.ornl.gov/hydro/triton.git
fi

pushd $TRITON_SRC_DIR || exit
git clean -fx || exit
git pull --ff-only || exit
popd || exit

if [ ! -d $TRISET_DIR ]; then
    git clone git@code.ornl.gov:hydro/triset.git
fi

# pushd $TSROOT || exit
# git clean -fx || exit
# git pull --ff-only || exit
# popd || exit
