#!/bin/bash
testname=$1
casename=$2
echo "USING LD_LIBRARY_PATH ${LD_LIBRARY_PATH}"
echo "GPMETIS=" $(which gpmetis)
echo "RUN $1 $2 Test"
if [ $testname == "echo" ];then

    # Echo test results as a test so the results are sent to CDASH separtely
    OUTPUT_DIR=$TEST_DIR_RUN/case_outputs
    cat $OUTPUT_DIR/$casename.log || exit

    if grep -E "FAIL|Traceback" $OUTPUT_DIR/$casename.log >> /dev/null
    then
        exit 1
    else
        exit 0
    fi
else
    LOGFILE=${TEST_DIR_RUN}/$1.log
    CMP_ACTIVATE=$(find $SCRATCH/MPAS/compass -name "load*compass*.sh")
    source $CMP_ACTIVATE
    pushd $TEST_DIR_RUN || exit
    compass run $1 | tee $LOGFILE || exit
    if grep -E "FAIL|Traceback" $LOGFILE >> /dev/null
    then
        exit 1
    else
        exit 0
    fi
fi