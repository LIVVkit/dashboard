
cmake_minimum_required (VERSION 2.8)
set (CTEST_DO_SUBMIT "$ENV{CTEST_DO_SUBMIT}")
set (CTEST_TEST_TYPE Nightly)
# What to build and test
set (DOWNLOAD_TRILINOS TRUE)
set (CLEAN_BUILD TRUE)
set (BUILD_TRILINOS TRUE)

# Begin User inputs:
set (CTEST_SITE "cori-knl") # generally the output of hostname
set (CTEST_DASHBOARD_ROOT "$ENV{TEST_DIRECTORY}" ) # writable path
set (CTEST_SCRIPT_DIRECTORY "$ENV{SCRIPT_DIRECTORY}" ) # where the scripts live
set (CTEST_CMAKE_GENERATOR "Unix Makefiles" ) # What is your compilation apps ?
set (CTEST_CONFIGURATION  Release) # What type of build do you want ?

set (INITIAL_LD_LIBRARY_PATH $ENV{LD_LIBRARY_PATH})

set (CTEST_PROJECT_NAME "LIVVkit" )
set (CTEST_SOURCE_NAME src)
set (CTEST_BUILD_NAME "Trilinos")
set (CTEST_BINARY_NAME build)


set (CTEST_SOURCE_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_SOURCE_NAME}")
set (CTEST_BINARY_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_BINARY_NAME}")

if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_SOURCE_DIRECTORY}")
endif ()
if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_BINARY_DIRECTORY}")
endif ()

configure_file ($ENV{CTEST_CONFIG_DIR}/CTestConfig.cmake
  ${CTEST_SOURCE_DIRECTORY}/CTestConfig.cmake COPYONLY)

set (CTEST_NIGHTLY_START_TIME "01:00:00 UTC")
set (CTEST_CMAKE_COMMAND "${PREFIX_DIR}/bin/cmake")
set (CTEST_COMMAND "${PREFIX_DIR}/bin/ctest -D${CTEST_TEST_TYPE}")
set (CTEST_FLAGS "-j16")
set (CTEST_BUILD_FLAGS "-j16")

set (CTEST_DROP_METHOD "http")


find_program (CTEST_GIT_COMMAND NAMES git)
find_program (CTEST_SVN_COMMAND NAMES svn)

set (Trilinos_REPOSITORY_LOCATION git@github.com:trilinos/Trilinos.git)

set(BOOST_DIR /usr/common/software/boost/1.70.0/gnu/haswell)
set(NETCDF_DIR $ENV{NETCDF_DIR})

if (CLEAN_BUILD)
  # Initial cache info
  set (CACHE_CONTENTS "
  SITE:STRING=${CTEST_SITE}
  CMAKE_TYPE:STRING=${CTEST_CONFIGURATION}
  CMAKE_GENERATOR:INTERNAL=${CTEST_CMAKE_GENERATOR}
  TESTING:BOOL=OFF
  PRODUCT_REPO:STRING=${Trilinos_REPOSITORY_LOCATION}
  " )

  ctest_empty_binary_directory( "${CTEST_BINARY_DIRECTORY}/TriBuild" )
  file(WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "${CACHE_CONTENTS}")
endif ()

if (DOWNLOAD_TRILINOS)

  set (CTEST_CHECKOUT_COMMAND)
 
  # Get Trilinos
  if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}/Trilinos")
    execute_process (COMMAND "${CTEST_GIT_COMMAND}" 
      clone ${Trilinos_REPOSITORY_LOCATION} -b develop ${CTEST_SOURCE_DIRECTORY}/Trilinos
      OUTPUT_VARIABLE _out
      ERROR_VARIABLE _err
      RESULT_VARIABLE HAD_ERROR)
    message(STATUS "out: ${_out}")
    message(STATUS "err: ${_err}")
    message(STATUS "res: ${HAD_ERROR}")
    if (HAD_ERROR)
      message(FATAL_ERROR "Cannot clone Trilinos repository!")
    endif ()
  endif ()

endif()


ctest_start(${CTEST_TEST_TYPE})

# Set Trilinos config options for MALI & build Trilinos

if (BUILD_TRILINOS) 
  message ("ctest state: BUILD_TRILINOS")
  # Configure Trilinos

  set(TRILINSTALLDIR  "${CTEST_BINARY_DIRECTORY}/TrilinosInstall")
  if (NOT EXISTS "${TRILINSTALLDIR}")
    file (MAKE_DIRECTORY "${TRILINSTALLDIR}")
  endif ()
  set (CMAKE_INSTALL_PREFIX "${TRILINSTALLDIR}")

  set (CONFIGURE_OPTIONS
  "-DCMAKE_INSTALL_PREFIX:PATH=${TRILINSTALLDIR}"
#
  "-DBoost_INCLUDE_DIRS:FILEPATH=${BOOST_DIR}/include"
  "-DNetcdf_LIBRARY_DIRS:FILEPATH=${NETCDF_DIR}/lib"
  "-DTPL_Netcdf_INCLUDE_DIRS:PATH=${NETCDF_DIR}/include"
  "-DBoostLib_LIBRARY_DIRS:FILEPATH=${BOOST_DIR}/lib"
  "-DBoostLib_INCLUDE_DIRS:FILEPATH=${BOOST_DIR}/include"
  "-DCMAKE_BUILD_TYPE:STRING=RELEASE"
  # "-DCMAKE_CXX_STANDARD=14"
  "-DTrilinos_WARNINGS_AS_ERRORS_FLAGS:STRING="
  "-DTrilinos_ENABLE_ALL_PACKAGES:BOOL=OFF"
  "-DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES:BOOL=OFF"
#
  "-DTrilinos_ENABLE_Fortran:BOOL=ON"
#
  "-DTPL_ENABLE_SuperLU:BOOL=OFF"
  "-DAmesos2_ENABLE_KLU2:BOOL=ON"
#
  "-DTrilinos_ASSERT_MISSING_PACKAGES=OFF"
  "-DTrilinos_ENABLE_Teuchos:BOOL=ON"
  "-DHAVE_TEUCHOS_COMM_TIMERS=ON"
  "-DTrilinos_ENABLE_Kokkos:BOOL=ON"
  "-DTrilinos_ENABLE_KokkosCore:BOOL=ON"
  "-DTrilinos_ENABLE_Zoltan:BOOL=ON"
  "-DTrilinos_ENABLE_Zoltan2:BOOL=ON"
  "-DTrilinos_ENABLE_Sacado:BOOL=ON"
  "-DTrilinos_ENABLE_Intrepid2:BOOL=ON"
  "-DTrilinos_ENABLE_Epetra:BOOL=ON"
  "-DTrilinos_ENABLE_Tpetra:BOOL=ON"
  "-DTrilinos_ENABLE_EpetraExt:BOOL=ON"
  "-DTrilinos_ENABLE_Ifpack:BOOL=ON"
  "-DTrilinos_ENABLE_Ifpack2:BOOL=ON"
  "-DTrilinos_ENABLE_AztecOO:BOOL=ON"
  "-DTrilinos_ENABLE_Amesos:BOOL=ON"
  "-DTrilinos_ENABLE_Amesos2:BOOL=ON"
  "-DTrilinos_ENABLE_Belos:BOOL=ON"
  "-DTrilinos_ENABLE_Phalanx:BOOL=ON"
  "-DTrilinos_ENABLE_ROL:BOOL=ON"
  "-DTrilinos_ENABLE_ML:BOOL=ON"
  "-DTrilinos_ENABLE_MueLu:BOOL=ON"
  "-DTrilinos_ENABLE_NOX:BOOL=ON"
  "-DTrilinos_ENABLE_Stratimikos:BOOL=ON"
  "-DTrilinos_ENABLE_Thyra:BOOL=ON"
  "-DTrilinos_ENABLE_ThyraTpetraAdapters:BOOL=ON"
  "-DTrilinos_ENABLE_Piro:BOOL=ON"
  "-DTrilinos_ENABLE_STKIO:BOOL=ON"
  "-DTrilinos_ENABLE_STKExprEval:BOOL=ON"
  "-DTrilinos_ENABLE_STKMesh:BOOL=ON"
  "-DTrilinos_ENABLE_SEACASExodus:BOOL=ON"
  "-DTrilinos_ENABLE_SEACASIoss:BOOL=ON"
  "-DTrilinos_ENABLE_SEACASEpu:BOOL=ON"
  "-DTrilinos_ENABLE_SEACASNemspread:BOOL=ON"
  "-DTrilinos_ENABLE_SEACASNemslice:BOOL=ON"
  "-DTrilinos_ENABLE_Pamgen:BOOL=ON"
  "-DTrilinos_ENABLE_Teko:BOOL=ON"
  "-DTrilinos_ENABLE_MiniTensor:BOOL=ON"
  "-DTrilinos_ENABLE_PanzerDofMgr:BOOL=ON"
  "-DTempus_ENABLE_TEUCHOS_TIME_MONITOR:BOOL=ON"
  "-DTrilinos_ENABLE_Tempus:BOOL=ON"
  "-DTempus_ENABLE_TESTS:BOOL=OFF"
  "-DTempus_ENABLE_EXAMPLES:BOOL=OFF"
  "-DTempus_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON"
#
  "-DTrilinos_ENABLE_TESTS:BOOL=OFF"
  "-DTrilinos_ENABLE_EXAMPLES:BOOL=OFF"
#
  "-DTPL_FIND_SHARED_LIBS:BOOL=ON"
  "-DBUILD_SHARED_LIBS:BOOL=ON"
  "-DTrilinos_LINK_SEARCH_START_STATIC:BOOL=ON"
#
  "-DKokkos_ENABLE_SERIAL:BOOL=ON"
  "-DKokkos_ENABLE_OPENMP:BOOL=OFF"
  "-DKokkos_ENABLE_PTHREAD:BOOL=OFF"
  "-DZoltan_ENABLE_ULONG_IDS:BOOL=ON"
  "-DZOLTAN_BUILD_ZFDRIVE:BOOL=OFF"
  "-DPhalanx_KOKKOS_DEVICE_TYPE:STRING=SERIAL"
  "-DPhalanx_INDEX_SIZE_TYPE:STRING=INT"
  "-DPhalanx_SHOW_DEPRECATED_WARNINGS:BOOL=OFF"
#
  "-DBoost_LIBRARY_DIRS:FILEPATH=${BOOST_DIR}/lib"
#
  "-DTPL_ENABLE_Netcdf:BOOL=ON"
#
  "-DTPL_ENABLE_BLAS:BOOL=ON"
  "-DBLAS_LIBRARY_NAMES:STRING="
  "-DLAPACK_LIBRARY_NAMES:STRING="
  "-DTPL_ENABLE_GLM:BOOL=OFF"
  "-DTPL_ENABLE_Matio:BOOL=OFF"
#
  "-DTPL_ENABLE_MPI:BOOL=ON"
  "-DTPL_ENABLE_Boost:BOOL=ON"
  "-DTPL_ENABLE_BoostLib:BOOL=ON"
#
  "-DCMAKE_VERBOSE_MAKEFILE:BOOL=OFF"
  "-DTrilinos_VERBOSE_CONFIGURE:BOOL=OFF"
#
  "-DTrilinos_ENABLE_EXPLICIT_INSTANTIATION:BOOL=ON"
  "-DTpetra_INST_INT_LONG_LONG:BOOL=ON"
  "-DTpetra_INST_INT_LONG:BOOL=OFF"
  "-DTpetra_INST_INT_INT:BOOL=OFF"
  "-DTpetra_INST_DOUBLE:BOOL=ON"
  "-DTpetra_INST_FLOAT:BOOL=OFF"
  "-DTpetra_INST_COMPLEX_FLOAT:BOOL=OFF"
  "-DTpetra_INST_COMPLEX_DOUBLE:BOOL=OFF"
  "-DTpetra_INST_INT_UNSIGNED:BOOL=OFF"
  "-DTpetra_INST_INT_UNSIGNED_LONG:BOOL=OFF"
#
  "-DMPI_USE_COMPILER_WRAPPERS:BOOL=OFF"
  "-DCMAKE_CXX_COMPILER:FILEPATH=CC"
  "-DCMAKE_C_COMPILER:FILEPATH=cc"
  "-DCMAKE_Fortran_COMPILER:FILEPATH=ftn"
  "-DTrilinos_ENABLE_Fortran=ON"
  "-DCMAKE_C_FLAGS:STRING=-O3 -DREDUCE_SCATTER_BUG"
  "-DCMAKE_CXX_FLAGS:STRING=-O3 -DREDUCE_SCATTER_BUG -DBOOST_NO_HASH"
  "-DTrilinos_ENABLE_SHADOW_WARNINGS=OFF"
  "-DTPL_ENABLE_Pthread:BOOL=OFF"
  "-DTPL_ENABLE_BinUtils:BOOL=OFF"
#
  "-DMPI_EXEC:FILEPATH=srun"
  "-DMPI_EXEC_MAX_NUMPROCS:STRING=4"
  "-DMPI_EXEC_NUMPROCS_FLAG:STRING=-n"
  "-DCMAKE_SKIP_INSTALL_RPATH=TRUE"
#
  "-DTrilinos_ENABLE_ShyLU_DDFROSch:BOOL=ON"
# 
  )

  if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}/TriBuild")
    file (MAKE_DIRECTORY ${CTEST_BINARY_DIRECTORY}/TriBuild)
  endif ()

  CTEST_CONFIGURE(
    BUILD "${CTEST_BINARY_DIRECTORY}/TriBuild"
    SOURCE "${CTEST_SOURCE_DIRECTORY}/Trilinos"
    OPTIONS "${CONFIGURE_OPTIONS}"
    RETURN_VALUE HAD_ERROR
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Configure
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message ("Cannot submit Trilinos configure results!")
    endif ()
  endif ()

  if (HAD_ERROR)
    message ("Cannot configure Trilinos build!")
  endif ()

  # Build Trilinos and install
  set (CTEST_BUILD_TARGET all)
  set (CTEST_BUILD_TARGET install)

  MESSAGE("\nBuilding target: '${CTEST_BUILD_TARGET}' ...\n")

  CTEST_BUILD(
    BUILD "${CTEST_BINARY_DIRECTORY}/TriBuild"
    RETURN_VALUE  HAD_ERROR
    NUMBER_ERRORS  BUILD_LIBS_NUM_ERRORS
    APPEND
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Build
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message ("Cannot submit Trilinos build results!")
    endif ()

  endif ()

  if (HAD_ERROR)
    message ("Cannot build Trilinos!")
  endif ()

  if (BUILD_LIBS_NUM_ERRORS GREATER 0)
    message ("Encountered build errors in Trilinos build. Exiting!")
  endif ()
  
  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Test
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message(FATAL_ERROR "Cannot submit Trilinos test results!")
    endif ()
  endif ()

  if (HAD_ERROR)
  	message(FATAL_ERROR "Some Trilinos tests failed.")
  endif ()

endif()
