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

    ready_machine = pyctest.command(["cp",
                                     os.path.join(_HERE, build_profile['configure_command']),
                                     os.path.join(_HERE, build_profile['build_command']),
                                     os.path.join(_HERE, build_profile['test_command']),
                                     "."])
    ready_machine.SetWorkingDirectory(pyctest.SOURCE_DIRECTORY)
    ready_machine.SetErrorQuiet(False)
    ready_machine.Execute()

    pyctest.CONFIGURE_COMMAND = " ".join(["bash", os.path.basename(build_profile['configure_command'])])
    pyctest.BUILD_COMMAND = " ".join(["bash", os.path.basename(build_profile['build_command'])])

    for test in build_profile['tests']:
        test_runner = pyctest.test()
        test_runner.SetName(test)
        test_runner.SetCommand(["bash", os.path.basename(build_profile['test_command']), test])
        test_runner.SetProperty("WORKING_DIRECTORY", pyctest.BINARY_DIRECTORY)

    pyctest.run(pyctest.ARGUMENTS)


if __name__ == "__main__":
    run(*parse_args())
