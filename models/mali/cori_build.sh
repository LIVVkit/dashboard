#!/bin/bash

pushd E3SM/components/mpas-albany-landice || exit
source $HOME/dashboard/nightly_scripts/mali_modules.sh

# note this version has no netcdf support
export PIO=$CSCRATCH/MPAS/Components/build/PIOInstall
source $CSCRATCH/MPAS/Components/build/AlbanyInstall/export_albany.in || exit

MPAS_EXTERNAL_LIBS="$ALBANY_LINK_LIBS -lstdc++"

make clean gnu-nersc \
USE_PIO2=true \
DEBUG=true \
PIO=$PIO \
MPAS_EXTERNAL_LIBS="$MPAS_EXTERNAL_LIBS" \
ALBANY=true || exit

chgrp -R piscees .
