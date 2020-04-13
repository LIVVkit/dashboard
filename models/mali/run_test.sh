#!/bin/bash
testname=$1
module load python
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

conda activate compass_py3.7
MALI_TEST_RUN_DIR=$HOME/MPAS/mali_test_run
MALI_TEST_OUT_DIR=$HOME/MPAS/mali_test_output/test

if [ $testname == "dome_2000m" ]
then
    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/2000m/halfar_analytic_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/dome/2000m/p1 
    pushd $TEST_DIR_RUN
    python setup_and_run_dome_testcase.py
    cp $TEST_DIR_RUN/run_model/*.png /project/projectdirs/piscees/www/mek/dome_2000m
    cp $TEST_DIR_RUN/run_model/* $TEST_DIR_OUT

elif [ $testname == "dome_variable" ]
then

    TEST_DIR_RUN=$MALI_TEST_RUN_DIR/landice/dome/variable_resolution/halfar_analytic_test
    TEST_DIR_OUT=$MALI_TEST_OUT_DIR/MALI/dome/dome/variable_resolution/p1 
    pushd $TEST_DIR_RUN || exit
    python setup_and_run_dome_testcase.py
    cp $TEST_DIR_RUN/run_model/*.png /project/projectdirs/piscees/www/mek/dome_variable
    cp $TEST_DIR_RUN/run_model/* $TEST_DIR_OUT

elif [ $testname == "livv" ]
then
    TEST_DIR=$HOME/MPAS/mali_test_output/test/MALI/
    REF_DIR=$HOME/MPAS/mali_test_output/reference/MALI/
    OUTDIR=/project/projectdirs/piscees/www/mek/vv_`date '+%Y_%m_%d'`
    livv -v $TEST_DIR $REF_DIR -o $OUTDIR
    chmod -R 0755 $OUTDIR

elif [ $testname == "hello_world" ]
then

    pushd MPAS-Model || exit
    git status

fi
echo "Results available at: https://portal.nersc.gov/project/piscees/mek/index.html"
echo "LIVV Results available at: https://portal.nersc.gov/project/piscees/mek/vv_`date '+%Y_%m_%d'`"
