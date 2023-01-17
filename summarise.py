#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Create summary e-mail for MALI or BISICLES nightly testing.
"""
import argparse
import datetime as dt
import os
import pickle as pk
import re
import xml.etree.ElementTree as ET
from collections import OrderedDict, namedtuple
from pathlib import Path

import git
import svn.local as svnl
from ruamel.yaml import YAML, YAMLError

CaseInfo = namedtuple(typename="CaseInfo", field_names=["name", "passed", "time"])
FAILED_TO_RUN = -86400 * 2
HLINE = "-" * 10


def args():
    """Define command line arguments."""
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawTextHelpFormatter
    )

    parser.add_argument(
        "-t",
        "--test_profile",
        help="A YAML file describing the test profile to summarise",
    )
    parser.add_argument(
        "-b",
        "--build_profile",
        help="A YAML file describing the build profile to summarise",
    )

    parser.add_argument(
        "-m", "--model", help="Model profile (oldmali, mali or bisicles)"
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
    """Use MALI xml test definition file to determine which cases should have run."""
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


def get_repo_info(test_root=None):
    """Get repository info for components and MALI."""
    if test_root is None:
        test_root = os.environ["SCRATCH"]
    _component_root = Path(test_root, "MPAS", "Components", "src")

    repo_locs = {
        "Albany": Path(_component_root, "Albany"),
        "PIO": Path(_component_root, "PIO"),
        "Trilinos": Path(_component_root, "Trilinos"),
        "COMPASS": Path(test_root, "MPAS", "compass"),
        # "MALI": Path(test_root, "MPAS", "MPAS-Model"),
        "MALI": Path(test_root, "MPAS", "E3SM"),
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
        _remotes = "\n".join(git_repo.remote().urls)
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
        except YAMLError as err:
            print(err)
            raise

    return ", ".join(emails[1:]), emails[0]


def read_mali_case(case):
    """Read file from MALI_Test/case_outputs, determine pass/fail and test time."""
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


def old_mali():
    """
    Assemble summary of testing and send email to interested folks.

    Parameters
    ----------
    cl_args : argparse.ArgumentParser
        Command line arguments

    Returns
    -------
    subject, email_text : string
        Subject line and body of e-mail to be sent

    """
    scratch_root = os.environ["SCRATCH"]
    in_dir = Path(scratch_root, "MPAS", "MALI_Test", "case_outputs")
    # Debug testing example
    # in_dir = Path(scratch_root, "MPAS", "MALI_2021-05-19", "case_outputs")
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

    header_text = "\n>>>>>> TESTS {} <<<<<<\n"
    email_text = f"{HLINE}\n|\/| /|| |\n|  |/-||_|\n{HLINE}\n"
    email_text += f"{'Run on':^10s}\n{run_date.strftime('%Y-%m-%d')}\n{HLINE}\n"
    email_text += f"Tests Run: {len(case_info)}\n"
    email_text += f"{'Passed:':>10s} {len(passes)}\n{'Failed:':>10s} {len(fails)}\n"
    email_text += f"{HLINE}\n"
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
    email_text += email_footer()

    subject = (
        f"[MALI Tests] {dt.datetime.now().strftime('%Y-%m-%d')}: "
        f"{len(passes)} / {len(case_info)} passed"
    )
    return subject, email_text


def parse_compass_log(log):
    """Read compass log, convert times for each test into `datetime.timedelta`."""
    time, status, name = log
    mins, secs = time.split(":")
    out_time = dt.timedelta(seconds=(int(mins) * 60 + int(secs)))
    passed = status == "PASS"
    return out_time, passed, name


def mali_compass(suite_name):
    """Parse output of compass v1.0 test suite."""
    # in_dir = Path("/global/cscratch1/sd/mek/MPAS/TestOutput/MALI_Test")
    in_dir = Path(os.environ["SCRATCH"], "MPAS", "TestOutput", "MALI_Test")
    test_def = Path(in_dir, f"{suite_name}.pickle")
    log_file = Path(in_dir, f"{suite_name}.log")
    run_date = dt.datetime.utcfromtimestamp(log_file.stat().st_ctime)
    with open(test_def, "rb") as _fin:
        suite = pk.load(_fin)

    case_canon = [
        case.replace("/", "_") for case in sorted(list(suite["test_cases"].keys()))
    ]

    with open(log_file, "r") as _fin:
        logs = _fin.readlines()
    try:
        times_s = logs.index("Test Runtimes:\n")
    except ValueError:
        print("TIMES NOT FOUND: TESTS PROBABLY TIMED OUT :-(")
        raise

    times_e = ["Total runtime" in _line for _line in logs].index(True)
    time_logs = logs[times_s + 1 : times_e]

    # Remove ANSI terminal colour escape chars
    esc_chars = re.compile(r"\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])")
    time_logs = [esc_chars.sub("", _line).strip().split(" ") for _line in time_logs]
    info = {}
    for line in time_logs:
        _time, _pass, _name = parse_compass_log(line)
        info[_name] = {"time": _time, "passed": _pass}

    total_time_case = dt.timedelta(0)
    for _case in info:
        total_time_case += info[_case]["time"]

    test_fails = []
    test_passes = []

    for case, caseinfo in info.items():
        if caseinfo["passed"]:
            test_passes.append(case)
        else:
            test_fails.append(case)

    cases_not_run = set(info.keys()).symmetric_difference(case_canon)
    if cases_not_run:
        for case in cases_not_run:
            info[case] = {
                "time": dt.timedelta(seconds=2 * FAILED_TO_RUN),
                "passed": False,
            }
        test_fails.extend(list(cases_not_run))

    header_text = "\n>>>>>> TESTS {} <<<<<<\n"
    email_text = f"{HLINE}\n|\/| /|| |\n|  |/-||_|\n{HLINE}\n"
    email_text += f"{'Run on':^10s}\n"
    email_text += f"{os.environ['SITE']:^10s}\n"
    email_text += f"{run_date.strftime('%Y-%m-%d')}\n"
    email_text += f"{HLINE}\n"
    email_text += f"Tests Run: {len(test_passes) + len(test_fails)}\n"
    email_text += (
        f"{'Passed:':>10s} {len(test_passes)}\n{'Failed:':>10s} {len(test_fails)}\n"
    )
    email_text += f"{HLINE}\n"

    email_text += header_text.format("PASSED")
    for case in test_passes:
        _name = " ".join(case.split("_")[1:-1])
        email_text += f"{_name:44s}: {info[case]['time']}\n"

    email_text += header_text.format("FAILED")
    for case in test_fails:
        _name = " ".join(case.split("_")[1:-1])
        email_text += f"{_name:44s}: {info[case]['time']}\n"

    email_text += f"\nTOTAL TIME: {total_time_case}\n"
    email_text += get_repo_info()
    email_text += email_footer()

    subject = (
        f"[MALI Tests] {dt.datetime.now().strftime('%Y-%m-%d')}: "
        f"{len(test_passes)} / {len(info)} passed on {os.environ['SITE']}"
    )

    return subject, email_text


def send_email(cl_args, model, subject, email_text):
    """
    Send e-mail with summary (or don't if cl_args indicate do-not-send)

    Parameters
    ----------
    cl_args : namespace
        Command line arguments, with at least "send" and "skip_confirm" arguments
    model : string
        Model name for e-mail profile name
    subject : string
        E-mail subject line
    email_text : string
        Multi-line string, first written to file, then e-mailed

    Returns
    -------
    None

    """
    out_file = Path(os.getcwd(), f"{model}_summary.txt")
    emails, primary = get_email_list(model)
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


def bisicles_repo(bisicles_dir):
    """Get SVN repository info for BISICLES."""
    output = f"\n{HLINE * 2} Repository Information {HLINE * 2}\n"
    # for sftwr in ["BISICLES", "Chombo"]:
    # for vers in ["release", "trunk"]:
    for sftwr, vers in [
        ("BISICLES", "trunk"),
        ("Chombo", "trunk"),
        ("Chombo", "release"),
    ]:
        repo_dir = Path(bisicles_dir, f"{sftwr}_{vers}")
        client = svnl.LocalClient(repo_dir)
        try:
            info = client.info()
        except ET.ParseError:
            output += "#### XML PARSE ERROR ####\n"
            continue

        # Make sure there aren't newer entries in the log...svn is weird?
        log = list(client.log_default(revision_from=info["commit_revision"]))
        latest = log[-1]
        try:
            message = f"{latest.msg.strip()}"
        except (TypeError, AttributeError):
            message = "NO MESSAGE"
        if len(message) > 70:
            message = f"{message[:70]}..."

        output += f"""{sftwr}: {vers}
        URL: {info['url']}
Current rev: {latest.revision}
    info rev: {info['commit_revision']}
        Author: {latest.author}
    Message: {message}
        Date: {latest.date.strftime('%Y-%m-%d %H:%M')}
"""
        output += f"{'-' * 55}\n"
    return output


def parse_bisicles_time(in_time):
    """Time delta is formatted in HH:MM:SS, translate this to datetime.timedelta."""
    assert len(in_time) == 8, "Time string not correct length"
    assert in_time[2] == in_time[5] == ":", "Time string not formatted as expected"
    hrs = int(in_time[:2])
    mins = int(in_time[3:5])
    secs = int(in_time[6:])
    total_seconds = secs + (mins * 60) + (hrs * 3600)
    return dt.timedelta(seconds=total_seconds)


def parse_bisicles_log(log_file):
    """Parse a BISICLES log file."""
    n_pass = 0
    n_fail = 0
    builds = {"r": "release", "t": "trunk"}
    name_fcn = lambda bld: f"Chombo {builds[bld[0]]}, BISICLES {builds[bld[1]]}"

    email_text = f"{'-' * 10} {name_fcn(log_file.name.split('_')[1])} {'-' * 10}\n"
    with open(log_file, "r") as _fin:
        test_data = _fin.readlines()

    test_info = OrderedDict()

    # Identify and get timings info for each test
    for idx, line in enumerate(test_data):
        if "time elapsed" in line:
            _info = line.split()
            # Crop the quotes from name
            try:
                time = parse_bisicles_time(_info[-1])
            except (AssertionError, ValueError):
                time = FAILED_TO_RUN

            test_info[_info[0][1:-1]] = {
                "time": time,
                "idx": idx,
            }

    # Now grab other data related now that we have the test names
    last_idx = 0
    for _test in test_info:
        curr_idx = test_info[_test]["idx"]
        test_info[_test]["other_data"] = test_data[last_idx : curr_idx + 3]
        last_idx = curr_idx
        if any("Passed" in _ for _ in test_info[_test]["other_data"]):
            test_info[_test]["passed"] = "Passed"
            n_pass += 1
        else:
            test_info[_test]["passed"] = "Failed"
            n_fail += 1

        email_text += (
            f"{_test:15s}: {test_info[_test]['time']} "
            f"{test_info[_test]['passed']}\n"
        )
    email_text += "\n"
    return email_text, n_pass, n_fail


def bisicles(bisicles_dir, date):
    """
    Summarise BISICLES nightly test logs.

    Parameters
    ----------
    bisicles_dir : Path
        Path to logfiles generated by testing (pyctest)
    date : string
        Date of testing to summarise (YYYY-MM-DD format)

    Returns
    -------
    subject, email_text : string
        Subject line and body of e-mail to be sent

    """
    log_files = sorted(Path(bisicles_dir, "test_logs").glob(f"test_*_{date}.log"))
    n_pass = 0
    n_fail = 0

    email_header = f"{HLINE * 3}\n|{'BISICLES TESTING RESULTS':^28s}|\n"
    email_header += f"|{'Run on':^28s}|\n|{date:^28s}|\n"
    email_header += f"{HLINE * 3}\n"

    email_body = ""
    for log_file in log_files:
        _text, _pass, _fail = parse_bisicles_log(log_file)
        email_body += _text
        n_pass += _pass
        n_fail += _fail

    email_header += f"    {n_pass} / {n_pass + n_fail} Passed Tests\n\n"
    email_body += bisicles_repo(bisicles_dir)

    email_text = email_header + email_body + email_footer()

    subject = (
        f"[BISICLES Tests] {dt.datetime.now().strftime('%Y-%m-%d')}: "
        f"{n_pass} / {n_pass + n_fail} passed"
    )
    return subject, email_text


def email_footer():
    """Define footer of e-mail."""
    email_text = "\n---\nSee latest dashboard for more details:\n"
    email_text += "https://my.cdash.org/index.php?project=LIVVkit\n"
    email_text += "---\nThis email is automatically generated by LIVVkit: dashboard\n"
    email_text += "https://github.com/LIVVkit/dashboard\n---\n"
    return email_text


def main(cl_args):
    """Choose which model to send summary for."""
    model = str(cl_args.model).lower()
    if model == "oldmali":
        subject, email_text = old_mali()

    elif model == "mali":
        subject, email_text = mali_compass("full_integration")

    elif model == "bisicles":
        curr_date = dt.datetime.now().strftime("%Y-%m-%d")
        subject, email_text = bisicles(
            Path("/global/cscratch1/sd/mek/bisicles"), curr_date
        )

    else:
        raise NotImplementedError(f"Model summary for {model} not defined")

    send_email(cl_args, model, subject, email_text)


if __name__ == "__main__":
    main(args())
