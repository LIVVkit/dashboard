#!/bin/bash

pushd E3SM/components/mpas-albany-landice || exit
source $HOME/dashboard/nightly_scripts/mali_modules.sh
module unload craype-hugepages2M
module load darshan

# note this version has no netcdf support
export PIO=$CSCRATCH/MPAS/Components/build/PIOInstall
source $CSCRATCH/MPAS/Components/build/AlbanyInstall/export_albany.in

export CRAYPE_LINK_TYPE=STATIC
MPAS_EXTERNAL_LIBS="$ALBANY_LINK_LIBS -lstdc++"
# CORE=landice

make clean gnu-nersc \
ALBANY=true \
USE_PIO2=true \
# CORE=$CORE \
PIO=$PIO \
MPAS_EXTERNAL_LIBS="$MPAS_EXTERNAL_LIBS" \
DEBUG=true \
EXE_NAME=landice_model || exit

chgrp -R piscees .
