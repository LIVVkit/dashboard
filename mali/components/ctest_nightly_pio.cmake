cmake_minimum_required (VERSION 2.8)
set (CTEST_DO_SUBMIT ON)
set (CTEST_TEST_TYPE Nightly)

# What to build and test
set (DOWNLOAD_PIO TRUE)
set (CLEAN_BUILD FALSE) 
set (BUILD_PIO TRUE)

# Begin User inputs:
set (CTEST_SITE "cori-knl" ) # Use cori-knl to match E3SM
set (CTEST_DASHBOARD_ROOT "$ENV{TEST_DIRECTORY}" ) # writable path
set (CTEST_SCRIPT_DIRECTORY "$ENV{SCRIPT_DIRECTORY}" ) # where the scripts live
set (CTEST_CMAKE_GENERATOR "Unix Makefiles" ) # What is your compilation apps?
set (CTEST_CONFIGURATION  Release) # What type of build do you want?

set (INITIAL_LD_LIBRARY_PATH $ENV{LD_LIBRARY_PATH})

set (CTEST_PROJECT_NAME "LIVVkit" )
set (CTEST_SOURCE_NAME src)
set (CTEST_BUILD_NAME "PIO")
set (CTEST_BINARY_NAME build)

set (CTEST_SOURCE_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_SOURCE_NAME}")
set (CTEST_BINARY_DIRECTORY "${CTEST_DASHBOARD_ROOT}/${CTEST_BINARY_NAME}")

if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_SOURCE_DIRECTORY}")
endif ()
if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}")
  file (MAKE_DIRECTORY "${CTEST_BINARY_DIRECTORY}")
endif ()

configure_file (${CTEST_SCRIPT_DIRECTORY}/CTestConfig.cmake
  ${CTEST_SOURCE_DIRECTORY}/CTestConfig.cmake COPYONLY)

set (CTEST_NIGHTLY_START_TIME "01:00:00 UTC")
set (CTEST_CMAKE_COMMAND "${PREFIX_DIR}/bin/cmake")
set (CTEST_COMMAND "${PREFIX_DIR}/bin/ctest -D ${CTEST_TEST_TYPE}")
set (CTEST_FLAGS "-j16")
set (CTEST_BUILD_FLAGS "-j16")

set (CTEST_DROP_METHOD "http")

find_program (CTEST_GIT_COMMAND NAMES git)

set (PIO_REPOSITORY_LOCATION git@github.com:NCAR/ParallelIO.git)
set(BOOST_DIR /usr/common/software/boost/1.70.0/gnu/haswell)
set(NETCDF_DIR "$ENV{NETCDF_DIR}")
set(PARALLEL_NETCDF_DIR "$ENV{PARALLEL_NETCDF_DIR}")

if (CLEAN_BUILD)
  # Initial cache info
  set (CACHE_CONTENTS "
  SITE:STRING=${CTEST_SITE}
  CMAKE_TYPE:STRING=Release
  CMAKE_GENERATOR:INTERNAL=${CTEST_CMAKE_GENERATOR}
  TESTING:BOOL=OFF
  PRODUCT_REPO:STRING=${PIO_REPOSITORY_LOCATION}
  ")

  ctest_empty_binary_directory( "${CTEST_BINARY_DIRECTORY}" )
  file(WRITE "${CTEST_BINARY_DIRECTORY}/CMakeCache.txt" "${CACHE_CONTENTS}")
endif ()


if (DOWNLOAD_PIO)

  set (CTEST_CHECKOUT_COMMAND)
  set (CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")
  
  # Get PIO
  if (NOT EXISTS "${CTEST_SOURCE_DIRECTORY}/PIO")
    execute_process (COMMAND "${CTEST_GIT_COMMAND}" 
      clone ${PIO_REPOSITORY_LOCATION} -b master ${CTEST_SOURCE_DIRECTORY}/PIO
      OUTPUT_VARIABLE _out
      ERROR_VARIABLE _err
      RESULT_VARIABLE HAD_ERROR)
    
    message(STATUS "out: ${_out}")
    message(STATUS "err: ${_err}")
    message(STATUS "res: ${HAD_ERROR}")
    if (HAD_ERROR)
      message(FATAL_ERROR "Cannot clone PIO repository!")
    endif ()
  endif ()

  set (CTEST_UPDATE_COMMAND "${CTEST_GIT_COMMAND}")

endif ()


ctest_start(${CTEST_TEST_TYPE})

if (BUILD_PIO)

  # Configure the PIO build
  set (CONFIGURE_OPTIONS
"-DCMAKE_INSTALL_PREFIX=${CTEST_BINARY_DIRECTORY}/PIOInstall"
"-DCMAKE_SYSTEM_NAME=Catamount"
"-DNETCDF_DIR=${NETCDF_DIR}"
"-DPNETCDF_DIR=${PARALLEL_NETCDF_DIR}"
"-DCMAKE_C_FLAGS=-O2 -DHAVE_NANOTIME -DBIT64 -DHAVE_VPRINTF -DHAVE_BACKTRACE -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY"
"-DCMAKE_Fortran_FLAGS=-O2 -DHAVE_NANOTIME -DBIT64 -DHAVE_VPRINTF -DHAVE_BACKTRACE -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY"
  )
  
  if (NOT EXISTS "${CTEST_BINARY_DIRECTORY}/PIOBuild")
    file (MAKE_DIRECTORY ${CTEST_BINARY_DIRECTORY}/PIOBuild)
  endif ()

  CTEST_CONFIGURE(
    BUILD "${CTEST_BINARY_DIRECTORY}/PIOBuild"
    SOURCE "${CTEST_SOURCE_DIRECTORY}/PIO"
    OPTIONS "${CONFIGURE_OPTIONS}"
    RETURN_VALUE HAD_ERROR
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Configure
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message ("Cannot submit PIO configure results!")
    endif ()
  endif ()

  if (HAD_ERROR)
    message ("Cannot configure PIO build!")
  endif ()

  # Build PIO and install
  set (CTEST_BUILD_TARGET install)

  MESSAGE("\nBuilding target: '${CTEST_BUILD_TARGET}' ...\n")

  CTEST_BUILD(
    BUILD "${CTEST_BINARY_DIRECTORY}/PIOBuild"
    RETURN_VALUE  HAD_ERROR
    NUMBER_ERRORS  BUILD_LIBS_NUM_ERRORS
    APPEND
    )

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Build
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message ("Cannot submit PIO build results!")
    endif ()

  endif ()

  if (HAD_ERROR)
    message ("Cannot build PIO!")
  endif ()

  if (BUILD_LIBS_NUM_ERRORS GREATER 0)
    message ("Encountered build errors in PIO build. Exiting!")
  endif ()

  if (CTEST_DO_SUBMIT)
    ctest_submit (PARTS Test
      RETURN_VALUE  S_HAD_ERROR
      )

    if (S_HAD_ERROR)
      message(FATAL_ERROR "Cannot submit PIO test results!")
    endif ()
  endif ()

  if (HAD_ERROR)
    message(FATAL_ERROR "Some PIO tests failed.")
  endif ()

endif()
