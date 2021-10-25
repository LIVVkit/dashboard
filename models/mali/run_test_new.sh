#!/bin/bash
testname=$1
casename=$2
TEST_DIR=$CSCRATCH/MPAS/NewTests/MALI_Test

echo "RUN $1 $2 Test"
if [ $testname == "echo" ];then

    # Echo test results as a test so the results are sent to CDASH separtely
    OUTPUT_DIR=$TEST_DIR/case_outputs
    cat $OUTPUT_DIR/$casename.log || exit

    if grep -E "FAIL|Traceback" $OUTPUT_DIR/$casename.log >> /dev/null
    then
        exit 1
    else
        exit 0
    fi
else
    LOGFILE=$CSCRATCH/MPAS/NewTests/MALI_Test/$1.log
    CMP_ACTIVATE=$(find $CSCRATCH/MPAS/compass -name "load*compass*.sh")
    source $CMP_ACTIVATE
    pushd $TEST_DIR || exit
    compass run $1 | tee $LOGFILE || exit
    if grep -E "FAIL|Traceback" $LOGFILE >> /dev/null
    then
        exit 1
    else
        exit 0
    fi
fi