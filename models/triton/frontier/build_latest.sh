#!/bin/bash

if [ ! $(command -v module) ];then
    source /usr/share/lmod/lmod/init/sh
fi
export HIP_PLATFORM=amd
export HIP_COMPILER=amdclang++
export MPICH_GPU_SUPPORT_ENABLED=1
export CRAY_CPU_TARGET=x86-64

# rm -f modfile.txt
# for modname in PrgEnv-amd amd rocm xpmem
# do
#     python -c "import subprocess as sp;mod_name = '${modname}';_test = sp.check_output(f'source /usr/share/lmod/lmod/init/sh && module -q -t spider {mod_name}', shell=True, stderr=sp.STDOUT);print(f'module load {[_mod.strip() for _mod in _test.decode().split() if mod_name in _mod][-1]}')" | tee -a modfile.txt
# done
# source modfile.txt
module purge
module --latest load PrgEnv-amd amd rocm xpmem craype-accel-amd-gfx90a
module -t list

pushd triton || exit
SRCDIR=./src BUILDDIR=./bld make clean frontier_gpu

# chgrp -R atm112 .
