## LIVVkit's Dashboard
*Build, test, and CDASH reporting worker for ice sheet models*

### THIS README IS CURRENTLY A WIP

---

Note:
* Github/SVN account details need to be saved for the user without requiring manual input (e.g., passwordless RSA key)
* repo exists and branch you want tested checked out already

----
## Nightly scripts
The nightly scripts to be called by (s)cron are in the `nightly_scripts` directory for each model.
For example for MALI on Perlmutter scron calls:

 - `dashboard/nightly_scripts/mali/build_and_test_mali_perlmutter_nightly.sh`
 - Which sets up the environment, cleans the build and source code directories then
 - Submits `build_software.sbatch` where the TPLs, MALI, and COMPASS are built on a shared node
 - Then the `mali_tests_perlmutter.sbatch` script is submitted to an exclusive node, where the tests are performed

## Use of pyctest
The MALI build, COMPASS build, and MALI Tests are carried out via `pyctest` where there are essentially 3 distinct work "phases":

  - model configuration
  - model building
  - test running

Once those phases are complete, pyctest will
then report the results to CDASH. In each of those phases, `pyctest` runs **a single**
specified script to actually *do* that phase, so each of those phases will need a
single script associated with it in the profile.

For these models, configuration and building are done separately to the running of tests so that each can be
performed inside or out of a queuing system (e.g. slurm).

For example, the basic MALI build profile on NERSC's CORI looks like:

```yaml
source_directory: /global/cscratch1/sd/mek/MPAS/MPAS-Model
build_directory: /global/cscratch1/sd/mek/MPAS
do_update: True
build_name: MALI-Build
configure_command: models/mali/cori_configure.sh
build_command: models/mali/cori_build.sh
cdash_section: MALI
```

And the test profile is similar, but has named tests.

```yaml
source_directory: /global/cscratch1/sd/mek/MPAS/MPAS-Model
build_directory: /global/cscratch1/sd/mek/MPAS
build_name: MALI-Test
build_command: models/mali/cori_setup_tests.sh
test_command: models/mali/run_test.sh
cdash_section: MALI
test_timeout: 5940
tests:
  - regsuite
```

For both the Configure and Build phases, the configure command and build command
are simply executed. For the test phase, `pyctest` will loop through all the
specified tests in the `tests:` profile section, and run them like:

```bash
bash [TEST_COMMAND] [TEST_NAME]
```

So for the above profile, it would look like:

```bash
bash run_test.sh regsuite
```

*Note: The command scripts are copied from their specified location in the profile to the
build build directory and everything is executed from within the build directory.*


###### pyctest gotchas
* Initially, I (Joe) tired to use the `pyctest` argument parser but holy hell, there are a lot of
options we don't need, and it does some weird things with arguments. Turns out, it's
easier to just write your own argument parser and just pass them to the `pyctest`
passer as default arguments to setup `pyctest`.
