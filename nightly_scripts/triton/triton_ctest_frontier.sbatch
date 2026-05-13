#!/bin/bash
#SBATCH -A ATM112
#SBATCH -J TRINIGHT
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -t 10
#SBATCH -C nvme

# Set proxy for cdash submission
export all_proxy=socks://proxy.ccs.ornl.gov:3128/
export ftp_proxy=ftp://proxy.ccs.ornl.gov:3128/
export http_proxy=http://proxy.ccs.ornl.gov:3128/
export https_proxy=http://proxy.ccs.ornl.gov:3128/
export no_proxy='localhost,127.0.0.0/8,*.ccs.ornl.gov'
CTEST_SCRIPT=testing.cmake

TRITON_TEST_DIR=/lustre/orion/atm112/proj-shared/mkelleher/nightly_testing/triton
ARCH_DIR=/lustre/orion/atm112/proj-shared/mkelleher/nightly_testing/archive
pushd ${TRITON_TEST_DIR} || exit
START_TIME=$(date +'%Y-%m-%dT%H%M')
LOGFILE=ctest_log_${START_TIME}.log

echo "LOG TO: ${TRITON_TEST_DIR}/${LOGFILE}"
export BACKEND=HIP
export COMPILER=cray

source ${TRITON_TEST_DIR}/cmake/machines/frontier/cray_HIP.sh
echo "****************************************" >> ${LOGFILE}
echo " CTEST WITH ${COMPILER} - ${BACKEND}" >> ${LOGFILE}
echo "****************************************" >> ${LOGFILE}
ctest -VV -S ${CTEST_SCRIPT} >> ${LOGFILE} 2>&1
sleep 2

echo "****************************************" >> ${LOGFILE}
echo " CTEST WITH ${COMPILER} - ${BACKEND} - ENSEMBLE" >> ${LOGFILE}
echo "****************************************" >> ${LOGFILE}
ENS=1 ctest -VV -S ${CTEST_SCRIPT} >> ${LOGFILE} 2>&1
sleep 2

export BACKEND=OPENMP
export COMPILER=cray
export MPICH_GPU_SUPPORT_ENABLED=0

for COMPILER in cray gnu
do
    echo "****************************************" >> ${LOGFILE}
    echo " CTEST WITH ${COMPILER} - ${BACKEND}" >> ${LOGFILE}
    echo "****************************************" >> ${LOGFILE}
    source ${TRITON_TEST_DIR}/cmake/machines/frontier/${COMPILER}_${BACKEND}.sh
    COMPILER=${COMPILER} ctest -VV -S ${CTEST_SCRIPT} >> ${LOGFILE} 2>&1
    sleep 2
done

ARCHIVE_OUT=${ARCH_DIR}/archive-${START_TIME}
mkdir -p ${ARCHIVE_OUT}
mv test-build-* ${ARCHIVE_OUT}