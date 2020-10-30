#!/usr/bin/env python
# -*- coding: utf-8 -*-
import glob
import datetime as dt
from pathlib import Path
import os
from ruamel.yaml import YAML, YAMLError
from collections import namedtuple
import sys
import git


def get_repo_info():
    """Get repository info for components and MALI."""
    _component_root = Path(os.environ["HOME"], "MPAS", "Components", "src")

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
        repo_info += f"{spc}{latest.summary}\n"
        repo_info += (
            f"{spc}{latest.author}: {latest.authored_datetime.strftime('%d %b %Y')}\n\n"
        )
    return repo_info


def get_email_list(profile_name, settings_dir=None):

    if settings_dir is None:
        settings_dir = os.environ["HOME"]
    with open(Path(settings_dir, f"{profile_name}_email_list.yml")) as stream:
        try:
            yaml = YAML(typ="safe")
            emails = yaml.load(stream)
        except YAMLError as e:
            print(e)
            raise

    return ", ".join(emails)


def main(send_mail=False):
    """
    Assemble summary of testing and send email to interested folks.

    Parameters
    ----------
    send_mail : boolean
        Send e-mail if true

    """
    scratch_root = os.environ["SCRATCH"]
    in_dir = Path(scratch_root, "MPAS", "MALI_Test", "case_outputs")
    cases = sorted(in_dir.glob("*"))
    CaseInfo = namedtuple(typename="CaseInfo", field_names=["name", "passed", "time"])
    case_info = []

    for case in cases:
        with open(case, "r") as _fin:
            case_data = _fin.read()
        _passed = "PASS" in case_data
        if "real " in case_data:
            try:
                _time = float(case_data[case_data.index("real ") :].split("\n")[0][5:])
            except TypeError:
                _time = -86400 * 2
        else:
            _time = -86400

        _info = CaseInfo(case.name, _passed, _time)
        case_info.append(_info)

    passes = [_case for _case in case_info if _case.passed]
    fails = [_case for _case in case_info if not _case.passed]

    header_text = "\n>>>>>> TESTS {} <<<<<<\n"
    email_text = "----------\n|\/| /|| |\n|  |/-||_|\n----------\n"
    email_text += f"Tests Run: {len(case_info)}\n   Passed: {len(passes)}\n   Failed: {len(fails)}\n"
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
    email_text += get_repo_info()
    subject = f"[MALI Tests] {dt.datetime.now().strftime('%Y-%m-%d')}: {len(passes)} / {len(case_info)} passed"
    with open("txt_summary.txt", "w") as _fout:
        _fout.write(email_text)

    emails = get_email_list("mali")
    mail_cmd = f'/usr/bin/mail -s "{subject}" "{emails}" -F "Michael Kelleher" < txt_summary.txt'
    if send_mail:
        os.system(mail_cmd)
    else:
        print(mail_cmd)
        print(email_text)


if __name__ == "__main__":
    main(True)
