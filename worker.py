#!/usr/bin/env python

import os
import platform

from pyctest import pyctest
from pyctest import helpers


def main():
    pyctest.PROJECT_NAME = "LIVVkit"

    ctest_dir = os.path.join(os.getcwd(), "pycm-test")
    pyctest.SOURCE_DIRECTORY = ctest_dir
    pyctest.BINARY_DIRECTORY = ctest_dir

    args = helpers.ArgumentParser(pyctest.PROJECT_NAME,
                                  pyctest.SOURCE_DIRECTORY,
                                  pyctest.BINARY_DIRECTORY,
                                  drop_site="my.cdash.org",
                                  drop_method="http").parse_args()

    pyctest.MODEL = "Experimental"
    pyctest.SITE = platform.node()

    test = pyctest.test()
    test.SetName("hello_cdash")
    test.SetCommand(["tree", ctest_dir])
    test.SetProperty("WORKING_DIRECTORY", os.getcwd())

    pyctest.run()


if __name__ == "__main__":
    main()
