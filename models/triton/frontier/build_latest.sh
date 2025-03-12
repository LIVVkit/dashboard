#!/bin/bash

if [ ! $(command -v module) ];then
    source /usr/share/lmod/lmod/init/sh
fi
export HIP_PLATFORM=amd
export HIP_COMPILER=amdclang++
export MPICH_GPU_SUPPORT_ENABLED=1
export CRAY_CPU_TARGET=x86-64

module purge
module --latest load PrgEnv-amd amd rocm xpmem craype-accel-amd-gfx90a
module -t list

pushd triton || exit
SRCDIR=./src BUILDDIR=./bld make clean frontier_gpu
