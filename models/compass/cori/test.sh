LOAD_COMPASS_SCRIPT=$(find $TEST_ROOT/compass -iname "load_*compass*.sh")
echo $LOAD_COMPASS_SCRIPT
source $LOAD_COMPASS_SCRIPT || exit
compass --version || exit