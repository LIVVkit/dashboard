#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Update testing results for COMPASS."""
import argparse
import os
from pathlib import Path
from xml.dom import minidom
import subprocess
import pickle as pk


def args():
    """Parse command line arguments for test and run."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "-d",
        "--test_date",
        required=True,
        help="Date of COMPASS test where new reference is located in YYYY-MM-DD format",
    )
    parser.add_argument(
        "-n",
        "--test_name",
        required=True,
        help=(
            "Name of test to be updated (e.g. dome_restart_test)\n"
            "This can also be a comma separated list of tests from the same run\n"
            "(e.g. HO_GIS_restart_test,HO_dome_decomposition_test"
        ),
    )
    parser.add_argument(
        "--legacy",
        required=False,
        help='Bless "legacy" compass tests',
        action="store_true",
        default=False,
    )

    return parser.parse_args()


def check_match(test_info):
    """Check that the names of output files match between ref and test."""
    # Right now, just check that they're the same length, later on this could
    # become more complicated
    return len(test_info["ref_output"]) == len(test_info["test_output"])


def dir_size(path):
    """Use UNIX du to determine size of directory."""
    return int(subprocess.check_output(["du", "-s", path]).split()[0].decode("utf-8"))


def get_test_info_legacy(tests, ref_root, test_root, test_name):
    """Get the reference and test directories for a COMPASS test."""
    test_names = [
        test.attributes["name"].value.replace(" ", "_").lower() for test in tests
    ]
    test_idx = test_names.index(test_name.lower())

    test = tests[test_idx]

    _dir = Path(
        test.attributes["core"].value,
        test.attributes["configuration"].value,
        test.attributes["resolution"].value,
        test.attributes["test"].value,
    )
    _test_dir = Path(test_root, _dir)
    _ref_dir = Path(ref_root, _dir)
    return {
        "test_name": test_name,
        "ref_dir": _ref_dir,
        "test_dir": _test_dir,
        "ref_output": sorted(_ref_dir.rglob("output*.nc")),
        "test_output": sorted(_test_dir.rglob("output*.nc"))
    }


def get_test_info(tests, ref_root, test_root, test_name):
    """Get output file paths for reference and test case for a particular `test_name`.
    """

    for _key in tests["test_cases"]:
        if test_name == _key.replace("/", "_"):
            test_key = _key

    _ref_dir = Path(ref_root, tests["test_cases"][test_key].path)
    _test_dir = Path(test_root, tests["test_cases"][test_key].path)

    return {
        "test_name": test_name,
        "ref_dir": _ref_dir,
        "test_dir": _test_dir,
        "ref_output": sorted(_ref_dir.rglob("output*.nc")),
        "test_output": sorted(_test_dir.rglob("output*.nc")),
    }


def move_files(test_info):
    """Move test files to reference directory."""
    _idx = 6
    print(
        f"Replace: {'/'.join(test_info['ref_dir'].parts[_idx:])} "
        f"({dir_size(test_info['ref_dir']) / 1024:.2f} KB, "
        f"{len(test_info['ref_output'])} output*.nc)"
    )
    print(
        f"   with: {'/'.join(test_info['test_dir'].parts[_idx:])} "
        f"({dir_size(test_info['test_dir']) / 1024:.2f} KB, "
        f"{len(test_info['test_output'])} output*.nc)"
    )
    confirm = input("Y / [N]: ")
    if confirm.lower() in ["yes", "y"]:
        _src = test_info["test_dir"]
        _dest = Path(*test_info["ref_dir"].parts[:-1])
        print(f"Copy {_src} to {_dest}")
        subprocess.call(["cp", "-LR", _src, _dest])
    else:
        print("Files remain unchanged")

    ref_log = Path(
        *test_info["ref_dir"].parts[: _idx + 1], "case_outputs", test_info["test_name"]
    )
    test_log = Path(
        *test_info["test_dir"].parts[: _idx + 1], "case_outputs", test_info["test_name"]
    )
    print(f"Overwrite: {ref_log}\n     with: {test_log}\n")
    if input("Y / [N]: ").lower() in ["yes", "y"]:
        subprocess.call(["cp", test_log, ref_log])


def main(cl_args):
    """Define stuff."""
    cscratch = os.environ["SCRATCH"]
    core = "landice"

    if cl_args.legacy:
        regsuite_file = Path(
            cscratch,
            "MPAS",
            "MPAS-Model",
            "testing_and_setup",
            "compass",
            core,
            "regression_suites",
            "combined_integration_test_suite.xml",
        )
        regsuite = minidom.parse(regsuite_file.as_posix())
        tests = regsuite.getElementsByTagName("test")

        ref_root = Path(cscratch, "MPAS", "MALI_Reference")
        new_ref = Path(cscratch, "MPAS", f"MALI_{cl_args.test_date}")

    else:
        ref_root = Path(cscratch, "MPAS", "TestOutput", "MALI_Reference")
        new_ref = Path(cscratch, "MPAS", "TestOutput", f"MALI_{cl_args.test_date}")
        regsuite_file = Path(new_ref, "full_integration.pickle")
        with open(regsuite_file, "rb") as _regfile:
            tests = pk.load(_regfile)

    test_names = cl_args.test_name.split(",")
    for test_name in test_names:
        test_name = test_name.strip()
        print(f"------BLESSING: {test_name}------")
        if cl_args.legacy:
            test_info = get_test_info_legacy(tests, ref_root, new_ref, test_name)
        else:
            test_info = get_test_info(tests, ref_root, new_ref, test_name)
        move_files(test_info)


if __name__ == "__main__":
    main(args())
