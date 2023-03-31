#!/bin/bash
#SBATCH -A m1041
#SBATCH -C cpu
#SBATCH --qos=regular
#SBATCH --time=00:20:00
#SBATCH --nodes=1
#SBATCH --job-name=test_mali
#SBATCH --output=%x-%a.log

soruce $HOME/dashboard/nightly_scripts/mali/mali_env.sh
echo "SUBMIT? ${CTEST_DO_SUBMIT}"
export CONDA_ENV=/global/common/software/piscees/mali/conda/pyctest
export PY_EXE=${CONDA_ENV}/bin/python
export LD_LIBRARY_PATH=$BASE_DIR/build/TrilinosInstall/lib:$BASE_DIR/build/AlbanyInstall/lib:$BASE_DIR/build/PIOInstall/lib:$LD_LIBRARY_PATH
test_dir=/global/homes/m/mek/dashboard
pushd $test_dir || exit

if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    SUBMIT_FLAG="-S"
else
    SUBMIT_FLAG=""
fi

$PY_EXE worker.py profiles/perlmutter/test_mali.yaml --site ${SITE} ${SUBMIT_FLAG}
