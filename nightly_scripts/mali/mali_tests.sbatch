#!/bin/bash
#SBATCH --qos=regular
#SBATCH --time=135
#SBATCH --nodes=1
#SBATCH --constraint=knl
echo "SUBMIT? ${CTEST_DO_SUBMIT}"
pyexe=/global/homes/m/mek/.conda/envs/pyctest/bin/python3
test_dir=/global/homes/m/mek/dashboard
pushd $test_dir || exit

if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    $pyexe worker.py profiles/test_mali_cori.yaml --site cori-knl -S
else
    $pyexe worker.py profiles/test_mali_cori.yaml --site cori-knl
fi