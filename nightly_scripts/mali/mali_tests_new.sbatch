#!/bin/bash
#SBATCH --qos=regular
#SBATCH --time=05:15:00
#SBATCH --nodes=1
#SBATCH --constraint=knl
echo "SUBMIT? ${CTEST_DO_SUBMIT}"
export CONDA_ENV=/global/common/software/piscees/mali/conda/pyctest
export PY_EXE=${CONDA_ENV}/bin/python

test_dir=/global/homes/m/mek/dashboard
pushd $test_dir || exit

if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    $PY_EXE worker.py profiles/test_mali_cori_new.yaml --site cori-knl -S
else
    $PY_EXE worker.py profiles/test_mali_cori_new.yaml --site cori-knl
fi
