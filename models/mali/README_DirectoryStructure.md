# MPAS - Albany - Land Ice (MALI) Model Nightly Testing Directory

This directory contains the source code, compiled binaries, and test results for the semi-nightly testing of MALI.

Current location: NERSC Cori
----------------------------
`/global/cscratch1/sd/mek/MPAS`

## Sub-directories

### Model build phase
- `Components`: Source and build directories for external dependency libraries
    - `src`: Source code
        - Trilinos
        - Albany
        - PIO
    - `build`: Binaries (Install) and CMake build directories (Bld)
        - Trilinos  (TriBuild, TrilinosInstall)
        - Albany (AlbBuild, AlbanyInstall)
        - PIO (PIOBuild, PIOInstall)
- `MPAS-Model`: Source code for MPAS-Model from https://github.com/MPAS-Dev/MPAS-Model/tree/landice/develop
    - `MPAS-Model/landice_model`: Most recent compiled model

### Model test phase
- `MALI_Reference`: Baseline directory of blessed test results
- `MALI_YYYY-MM-DD`: Testing output directory for given date, compared to `MALI_Reference`
- `MALI_NotAReference`: Non-reference which is different from `MALI_Reference` for use with LIVVkit plotting tests
- `MPAS-Tools`: MPAS Tools (mesh, postprocessing, etc.) https://github.com/MPAS-Dev/MPAS-Tools/tree/landice/develop