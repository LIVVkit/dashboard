#!/bin/bash
#SBATCH --qos=regular
#SBATCH --time=20
#SBATCH --nodes=1
#SBATCH --constraint=knl

pyexe=/global/common/software/piscees/mali/conda/pyctest/bin/python3
test_dir=/global/homes/m/mek/dashboard
pushd $test_dir || exit
if [ $CTEST_DO_SUBMIT ]; then
    $pyexe worker.py profiles/test_bisicles_cori.yaml --site cori-knl -S
else
    $pyexe worker.py profiles/test_bisicles_cori.yaml --site cori-knl
fi
