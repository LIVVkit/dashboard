## LIVVkit's Dashboard
*Build, test, and CDASH reporting worker for ice sheet models*

## THIS README IS CURRENTLY A WIP AND SUCKS. SORRY

---

Note:
* Github/SVN account details need to be saved for the user without requiring manual input (e.g., passwordless RSA key)
* repo exists and branch you want tested checked out already




---- 

There are essentially 3 distinct work "phases": model configuration, 
model building, and test running. Once those phases are complete, pyctest will 
then report the results to CDASH. In each of those phases, `pyctest` runs **a single**
specified script to actually *do* that phase, so each of those phases will need a 
single script associated with it in the profile. 

For example, the basic MALI profile on NERSC's CORI looks like:

```yaml
source_directory: /global/homes/k/kennedyj/MPAS  # NERSC
build_directory: /global/homes/k/kennedyj/MPAS   # NERSC
build_name: MALI
configure_command: models/mali/cori_configure.sh
build_command: models/mali/cori_build.sh
test_command: models/mali/run_test.sh
cdash_section: Ice_sheet_models
tests:
  - hello_world
```

For both the Configure and Build phases, the configure command and build command
are simply executed. For the test phase, `pyctest` will loop through all the 
specified tests in the `tests:` profile section, and run them like:

```bash
bash [TEST_COMMAND] [TEST_NAME]
```

So for the above profile, it would look like:

```bash
bash run_tests.sh hello_world
```

*Note: The command scripts are copied from their specified location in the profile to the 
build build directory and everything is executed from withing the build directory.*


###### pyctest gotchas
* Initially, I tired to use the `pyctest` argument parser but holy hell, there are a lot of 
options we don't need, and it does some weird things with arguments. Turns out, it's
easier to just write your own argument parser and just pass them to the `pyctest`
passer as default arguments to setup `pyctest`.  
