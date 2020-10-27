#!/bin/bash
#SBATCH --qos=regular
#SBATCH --time=130
#SBATCH --nodes=1
#SBATCH --constraint=knl

pyexe=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
test_dir=/global/homes/m/mek/dashboard
pushd $test_dir || exit
$pyexe worker.py profiles/test_mali_cori.yaml --site cori-knl -S
