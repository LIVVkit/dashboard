#!/usr/bin/env python
"""
Run a build and test profile for reporting to LIVVkit's CDash board
"""

import argparse
import os
import platform

from ruamel.yaml import YAML, YAMLError

from pyctest import pyctest
from pyctest import helpers

_HERE = os.path.abspath(os.path.dirname(__file__))


def parse_args(cl_args=None):
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('profile',
                        help='A YAML file describing the build and test profile to run')

    parser.add_argument('--site',
                        help="Specify the site name",
                        default=None)

    parser.add_argument("-S", "--submit",
                        help="Submit test results to CDASH",
                        action='store_true',
                        default=False)

    worker_args = parser.parse_args(cl_args)
    if worker_args.site is None:
        worker_args.site = platform.node()

    with open(worker_args.profile) as stream:
        try:
            yaml = YAML(typ='safe')
            build_profile = yaml.load(stream)
        except YAMLError as e:
            print(e)

    # NOTE: Just use defaults
    pyctest_args = helpers.ArgumentParser(
            "LIVVkit",
            build_profile['source_directory'],
            build_profile['build_directory'],
            drop_site="my.cdash.org",
            drop_method="http",
            site=worker_args.site,
            submit=worker_args.submit
    ).parse_args(args=[])

    return build_profile, pyctest_args


def run(build_profile, pyctest_args):
    pyctest.MODEL = build_profile['cdash_section']
    pyctest.BUILD_NAME = build_profile['build_name']

    # Test Timeout set in build profile, otherwise default to 10 minutes
    test_timeout = build_profile.get("test_timeout", 600)

    _ready_command = ["cp"]
    for cmd in ["configure_command", "build_command", "test_command"]:
        if cmd in build_profile:
            _ready_command.append(os.path.join(_HERE, build_profile[cmd]))
    _ready_command.append(".")
    ready_machine = pyctest.command(_ready_command)

    ready_machine.SetWorkingDirectory(pyctest.BINARY_DIRECTORY)
    ready_machine.SetErrorQuiet(False)
    ready_machine.Execute()
    helpers.Cleanup(pyctest.BINARY_DIRECTORY)

    if "configure_command" in build_profile:
        pyctest.CONFIGURE_COMMAND = " ".join(["bash", os.path.basename(build_profile['configure_command'])])

    if "build_command" in build_profile:
        pyctest.BUILD_COMMAND = " ".join(["bash", os.path.basename(build_profile['build_command'])])

    if "tests" in build_profile:
        for test in build_profile['tests']:
            test_runner = pyctest.test(properties={"TIMEOUT": f"{test_timeout:d}"})
            test_runner.SetName(test)
            test_runner.SetCommand(["bash", os.path.basename(build_profile['test_command']), test])
            test_runner.SetProperty("WORKING_DIRECTORY", pyctest.BINARY_DIRECTORY)
    pyctest.run(pyctest.ARGUMENTS)


if __name__ == "__main__":
    run(*parse_args())
