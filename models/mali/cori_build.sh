#!/bin/bash

pushd E3SM/components/mpas-albany-landice || exit
source $HOME/dashboard/nightly_scripts/mali_modules.sh

# note this version has no netcdf support
export PIO=$SCRATCH/MPAS/Components/build/PIOInstall
export LD_LIBRARY_PATH=$BASE_DIR/build/TrilinosInstall/lib:$BASE_DIR/build/AlbanyInstall/lib:$BASE_DIR/build/PIOInstall/lib:$LD_LIBRARY_PATH
source $SCRATCH/MPAS/Components/build/AlbanyInstall/export_albany.in || exit

MPAS_EXTERNAL_LIBS="$ALBANY_LINK_LIBS -lstdc++"

# make clean intel-nersc \
make clean gnu-nersc \
USE_PIO2=true \
DEBUG=true \
PIO=$PIO \
MPAS_EXTERNAL_LIBS="$MPAS_EXTERNAL_LIBS" \
ALBANY=true | tee $TEST_ROOT/mali_build_log_$(date +'%Y-%m-%d').log || exit

chgrp -R piscees .
