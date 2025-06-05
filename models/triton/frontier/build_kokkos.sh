#!/bin/bash

if [ ! $(command -v module) ];then
    source /usr/share/lmod/lmod/init/sh
fi

pushd ${TRITON_KOKKOS_DIR}/build || exit
source machines/frontier/frontier_gpu.env
make -j