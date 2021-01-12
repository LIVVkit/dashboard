#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import datetime as dt
import glob
import os
import sys
import xml.etree.ElementTree as ET
from collections import namedtuple
from pathlib import Path

import git
from ruamel.yaml import YAML, YAMLError


CaseInfo = namedtuple(typename="CaseInfo", field_names=["name", "passed", "time"])
FAILED_TO_RUN = -86400 * 2


def args():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "-t" "--test_profile",
        help="A YAML file describing the test profile to summarise",
    )
    parser.add_argument(
        "-b" "--build_profile",
        help="A YAML file describing the build profile to summarise",
    )

    parser.add_argument(
        "-S",
        "--send",
        help="Send e-mail if present, otherwise print to stdout",
        action="store_true",
        default=False,
    )

    parser.add_argument(
        "-C",
        "--skip_confirm",
        help="Skip confirmation before sending e-mail",
        action="store_true",
        default=False,
    )
    return parser.parse_args()


def get_unrun_cases(case_dir):

    reg_file = Path(case_dir, "../", "regression.xml")
    regsuite = ET.parse(reg_file)

    suite_cases = [
        "_".join(case.attrib["name"].split())
        for case in regsuite.iter()
        if case.tag == "test"
    ]

    test_cases = [_out.name for _out in case_dir.glob("*")]
    tests_not_run = list(set(suite_cases).difference(test_cases))
    return tests_not_run


def get_repo_info():
    """Get repository info for components and MALI."""
    _component_root = Path(os.environ["CSCRATCH"], "MPAS", "Components", "src")

    repo_locs = {
        "Albany": Path(_component_root, "Albany"),
        "PIO": Path(_component_root, "PIO"),
        "Trilinos": Path(_component_root, "Trilinos"),
        "MALI": Path(os.environ["CSCRATCH"], "MPAS", "MPAS-Model"),
    }
    repo_info = "\n\n>>>>>> Source Repositories <<<<<<\n"
    spc = "      "

    for repo in repo_locs:
        git_repo = git.Repo(repo_locs[repo])
        latest = git_repo.head.commit

        repo_info += (
            f"{spc}{'-' * (10 + len(str(git_repo.active_branch)) + len(repo))}\n"
        )
        repo_info += f"{spc}{repo} ({git_repo.active_branch}) {latest.hexsha[:6]}\n"
        repo_info += (
            f"{spc}{'-' * (10 + len(str(git_repo.active_branch)) + len(repo))}\n"
        )
        _remotes = "\n".join([i for i in git_repo.remote().urls])
        repo_info += f"{spc}Tracked from: {_remotes}\n"
        repo_info += f"{spc}{latest.summary}\n"
        repo_info += (
            f"{spc}{latest.author}: {latest.authored_datetime.strftime('%d %b %Y')}\n\n"
        )
    return repo_info


def get_email_list(profile_name, settings_dir=None):
    """
    Read YML file with emails (not version controlled in git repository).

    Stored in this format:
    - user1@hosta.gov
    - user2@hostb.org
    ...
    - usern@hostz.com

    """
    if settings_dir is None:
        settings_dir = os.environ["HOME"]
    with open(Path(settings_dir, f"{profile_name}_email_list.yml")) as stream:
        try:
            yaml = YAML(typ="safe")
            emails = yaml.load(stream)
        except YAMLError as e:
            print(e)
            raise

    return ", ".join(emails[1:]), emails[0]


def read_mali_case(case):
    with open(case, "r") as _fin:
        case_data = _fin.read()
    _passed = "PASS" in case_data and not "FAIL" in case_data

    if "real " in case_data:
        try:
            _time = int(float(case_data[case_data.index("real ") :].split("\n")[0][5:]))
        except TypeError:
            _time = FAILED_TO_RUN // 2
    else:
        _time = FAILED_TO_RUN
    return CaseInfo(case.name, _passed, _time)


def main(cl_args):
    """
    Assemble summary of testing and send email to interested folks.

    Parameters
    ----------
    cl_args : argparse.ArgumentParser
        Command line arguments

    """
    scratch_root = os.environ["CSCRATCH"]
    in_dir = Path(scratch_root, "MPAS", "MALI_Test", "case_outputs")
    cases = sorted(in_dir.glob("*"))
    run_date = dt.datetime.utcfromtimestamp(cases[0].stat().st_ctime)

    case_info = []

    for case in cases:
        _info = read_mali_case(case)
        case_info.append(_info)

    # Add the tests from the regression suite that were not run as fails
    for case_not_run in get_unrun_cases(in_dir):
        case_info.append(
            CaseInfo(name=case_not_run, passed=False, time=FAILED_TO_RUN * 2)
        )

    passes = [_case for _case in case_info if _case.passed]
    fails = [_case for _case in case_info if not _case.passed]

    hline = "-" * 10
    header_text = "\n>>>>>> TESTS {} <<<<<<\n"
    email_text = f"{hline}\n|\/| /|| |\n|  |/-||_|\n{hline}\n"
    email_text += f"{'Run on':^10s}\n{run_date.strftime('%Y-%m-%d')}\n{hline}\n"
    email_text += f"Tests Run: {len(case_info)}\n{'Passed:':>10s} {len(passes)}\n{'Failed:':>10s} {len(fails)}\n"
    email_text += f"{hline}\n"
    txt_line = (
        lambda _case: f"   {_case.name:41s}: {dt.timedelta(seconds=_case.time)}\n"
    )

    if passes:
        email_text += header_text.format("PASSED")
        for _case in passes:
            email_text += txt_line(_case)

    if fails:
        email_text += header_text.format("FAILED")
        for _case in fails:
            email_text += txt_line(_case)
        email_text += "\n>>>>>> NOTE ON NEGATIVE TIMES <<<<<<\n"
        email_text += "      time = -1 day -> the time was not parsed correctly\n"
        email_text += "      time = -2 days -> test failed to complete\n"
        email_text += "      time = -4 days -> test not run, but ought to have been\n"
    email_text += get_repo_info()

    email_text += "\n---\nSee latest dashboard for more details:\n"
    email_text += "https://my.cdash.org/index.php?project=LIVVkit\n"
    email_text += "---\nThis email is automatically generated by LIVVkit: dashboard\n"
    email_text += "https://github.com/LIVVkit/dashboard\n---\n"

    subject = f"[MALI Tests] {dt.datetime.now().strftime('%Y-%m-%d')}: {len(passes)} / {len(case_info)} passed"

    emails, primary = get_email_list("mali")
    out_file = Path(os.getcwd(), "txt_summary.txt")

    mail_cmd = f'/usr/bin/mailx -s "{subject}" -b "{emails}" "{primary}" < {out_file}'

    if cl_args.send:
        with open(out_file, "w") as _fout:
            _fout.write(email_text)

        _frame = "x"
        print(f"{45 * _frame}\n{_frame}{'SENDING E-MAIL':^43s}{_frame}\n{45 * _frame}")
        print(mail_cmd)
        if cl_args.skip_confirm:
            os.system(mail_cmd)
        else:
            confirm = input(f"Send e-mail to\n{emails}\n y / [n]: ")
            if confirm.upper() in ["Y", "YES"]:
                os.system(mail_cmd)
            else:
                print("E-mail not sent")

    else:
        print(mail_cmd)
        print(email_text)


if __name__ == "__main__":
    main(args())
