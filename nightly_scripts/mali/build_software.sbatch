#!/bin/bash
#SBATCH -A m1041
#SBATCH --qos=shared
#SBATCH --job-name=build_mali_tpl
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32GB
#SBATCH --output=%x-%a.log
#SBATCH -C cpu

source $HOME/dashboard/nightly_scripts/mali/mali_env.sh
source $CTEST_CONFIG_DIR/mali_modules_${MACHINE_HOST}.sh

# Build required components for MALI (no tests run on these)
printf "Build components\n"
/usr/bin/time -f "PIO time: %E (%e) mem: %M KB cpu: %P" bash -l -c "${NIGHTLY_SCRIPT_DIR}/components/cron_script_pio.sh"
/usr/bin/time -f "TRL time: %E (%e) mem: %M KB cpu: %P" bash -l -c "${NIGHTLY_SCRIPT_DIR}/components/cron_script_trilinos.sh"
/usr/bin/time -f "ALB time: %E (%e) mem: %M KB cpu: %P" bash -l -c "${NIGHTLY_SCRIPT_DIR}/components/cron_script_albany.sh"

# Now perform MALI build
printf "Build MALI\n"

pushd $DASH_DIR || exit
if [ ${CTEST_DO_SUBMIT} == "ON" ]
then
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_mali.yaml --site ${SITE} -S || exit
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_compass.yaml --site ${SITE} -S || exit
else
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_mali.yaml --site ${SITE} || exit
    $PY_EXE worker.py profiles/${MACHINE_HOST}/build_compass.yaml --site ${SITE} || exit
fi