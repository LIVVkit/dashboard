#!/bin/bash
testname=$1
casename=$2
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/usr/common/software/python/3.7-anaconda-2019.07/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/usr/common/software/python/3.7-anaconda-2019.07/etc/profile.d/conda.sh" ]; then
        . "/usr/common/software/python/3.7-anaconda-2019.07/etc/profile.d/conda.sh"
    else
        export PATH="/usr/common/software/python/3.7-anaconda-2019.07/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
TEST_ROOT=$CSCRATCH

module load nco
conda activate compass_py3.7
MALI_TEST_RUN_DIR=$TEST_ROOT/MPAS/mali_test_run
MALI_TEST_OUT_DIR=$HOME/MPAS/mali_test_output/test

MALI_COMMIT=`cd $TEST_ROOT/MPAS/MPAS-Model && git log -p -1`
echo "Hostname: "`hostname`

if [ $testname == "dome_2000m" ]
then
    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/2000m/halfar_analytic_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/dome/2000m/p1
    pushd $TEST_DIR_RUN
    python setup_and_run_dome_testcase.py || exit
    cp $TEST_DIR_RUN/run_model/*.png /project/projectdirs/piscees/www/mek/dome_2000m
    cp $TEST_DIR_RUN/run_model/* $TEST_DIR_OUT

elif [ $testname == "dome_variable" ]
then

    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/variable_resolution/halfar_analytic_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/dome/variable_resolution/p1
    pushd $TEST_DIR_RUN || exit
    python setup_and_run_dome_testcase.py || exit
    cp $TEST_DIR_RUN/run_model/*.png /project/projectdirs/piscees/www/mek/dome_variable
    cp $TEST_DIR_RUN/run_model/* $TEST_DIR_OUT

elif [ $testname == "ho_restart" ]
then

    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/2000m/ho_restart_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/ho_restart_test/2000m/p1
    pushd $TEST_DIR_RUN || exit
    python setup_and_run_dome_testcase.py || exit
    cp $TEST_DIR_RUN/restart_run/*.png /project/projectdirs/piscees/www/mek/$testname
    cp $TEST_DIR_RUN/restart_run/* $TEST_DIR_OUT

elif [ $testname == "ho_decomposition" ]
then

    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/2000m/ho_decomposition_test
    TEST_DIR_OUT_1=$MALI_TEST_OUT_DIR/MALI/dome/ho_decomposition_test/2000m/p1
    TEST_DIR_OUT_4=$MALI_TEST_OUT_DIR/MALI/dome/ho_decomposition_test/2000m/p4
    pushd $TEST_DIR_RUN || exit
    python setup_and_run_dome_testcase.py || exit
    cp $TEST_DIR_RUN/1proc_run/*.png /project/projectdirs/piscees/www/mek/$testname
    cp $TEST_DIR_RUN/1proc_run/* $TEST_DIR_OUT_1
    cp $TEST_DIR_RUN/4proc_run/* $TEST_DIR_OUT_4

elif [ $testname == "ho_vs_sia" ]
then

    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/2000m/ho_vs_sia_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/ho_vs_sia_test/2000m/p1
    pushd $TEST_DIR_RUN || exit
    python setup_and_run_dome_testcase.py || exit
    cp $TEST_DIR_RUN/ho_run/*.png /project/projectdirs/piscees/www/mek/$testname
    cp $TEST_DIR_RUN/ho_run/* $TEST_DIR_OUT

elif [ $testname == "ho_regsuite" ]
then
    # Check if yesterday's test was archived (may not happen if tests time out before archive step)

    yesterday_arch=$CSCRATCH/MALI/MALI_`date --date="1 day ago" +"%Y-%m-%d"`
    TEST_DIR_RUN=$CSCRATCH/MPAS/MALI_Test
    TEST_DIR_ARCH=$CSCRATCH/MPAS/MALI_`date +"%Y-%m-%d"`

    if [[ ! -d $yesterday_arch && -d $TEST_DIR_RUN ]]; then
        cp -R $TEST_DIR_RUN $yesterday_arch
    fi

    mkdir -p $TEST_DIR_OUT
    pushd $TEST_DIR_RUN || exit
    python ho_integration_test_suite.py || exit
    cp -R $TEST_DIR_RUN $TEST_DIR_ARCH

elif [ $testname == "regsuite" ]
then
    TEST_DIR_RUN=$TEST_ROOT/MPAS/MALI_Test
    TEST_DIR_ARCH=$TEST_ROOT/MPAS/MALI_`date +"%Y-%m-%d"`

    pushd $TEST_DIR_RUN || exit
    python combined_integration_test_suite.py || exit
    cp -R $TEST_DIR_RUN $TEST_DIR_ARCH

elif [ $testname == "livv" ]
then
    TEST_DIR=$HOME/MPAS/mali_test_output/test/MALI/
    REF_DIR=$HOME/MPAS/mali_test_output/reference/MALI/
    OUTDIR=/project/projectdirs/piscees/www/mek/vv_`date '+%Y_%m_%d'`
    livv -v $TEST_DIR $REF_DIR -o $OUTDIR || exit
    chmod -R 0755 $OUTDIR
    ln -sf $OUTDIR /project/projectdirs/piscees/www/latest
    echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
    echo "LIVV Results available at: https://portal.nersc.gov/project/piscees/mek/vv_`date '+%Y_%m_%d'`"


elif [[ $testname == "echo" ]]
then

    # Echo test results as a test so the results are sent to CDASH separtely
    TEST_DIR=$TEST_ROOT/MPAS/MALI_Test/case_outputs
    # TEST_DIR_ARCH=$HOME/Data/MALI_Test/case_outputs
    cat $TEST_DIR/$casename || exit

    if grep -E "FAIL|Traceback" $TEST_DIR/$casename >> /dev/null || ! grep -E "real\ " $TEST_DIR/$casename >> /dev/null
    then
        exit 1
    else
        exit 0
    fi

elif [ $testname == "hello_world" ]
then

    pushd MPAS-Model || exit
    git status

fi
