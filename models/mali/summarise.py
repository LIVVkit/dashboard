#!/usr/bin/env python
# -*- coding: utf-8 -*-
import glob
from datetime import datetime
from pathlib import Path
import os
from ruamel.yaml import YAML, YAMLError
from collections import namedtuple
import sys


def main():
    with open("email_list.yml") as stream:
        try:
            yaml = YAML(typ="safe")
            emails = yaml.load(stream)
        except YAMLError as e:
            print(e)
            raise
    emails = ", ".join(emails)

    scratch_root = os.environ["SCRATCH"]
    in_dir = Path(scratch_root, "MPAS", "MALI_Test", "case_outputs")
    cases = in_dir.glob("*")
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
                _time = -999.0
        else:
            _time = -9999.0

        _info = CaseInfo(case.name, _passed, _time)
        case_info.append(_info)

    passes = [_case for _case in case_info if _case.passed]
    fails = [_case for _case in case_info if not _case.passed]

    header_text = "\n>>>>>> TESTS {} <<<<<<\n"

    email_text = f"Tests Run: {len(case_info)}\n   Passed: {len(passes)}\n   Failed: {len(fails)}\n"
    txt_line = lambda _case: f"   {_case.name:41s}: {_case.time:.1f}s\n"

    if passes:
        email_text += header_text.format("PASSED")
        for _case in passes:
            email_text += txt_line(_case)

    if fails:
        email_text += header_text.format("FAILED")
        for _case in fails:
            email_text += txt_line(_case)

    subject = f"[MALI Tests] {datetime.now().strftime('%Y-%m-%d')}: {len(passes)} / {len(case_info)} passed"
    with open("summary.txt", "w") as _fout:
        _fout.write(email_text)

    mail_cmd = (
        f'/usr/bin/mail -s "{subject}" "{emails}" -F "Michael Kelleher" < summary.txt'
    )
    os.system(mail_cmd)


if __name__ == "__main__":
    main()


"""
>>> import git
>>> alb = git.Repo("/global/homes/m/mek/MPAS/Components/src/Albany")
>>> alb
<git.repo.base.Repo '/global/homes/m/mek/MPAS/Components/src/Albany/.git'>
>>> tree = alb.heads.master.commit.tree
>>> tree
<git.Tree "bee314615f63fd3a12c19cbfe917d376c06bde5a">
>>> alb.head
<git.HEAD "HEAD">
>>> alb.commit
<bound method Repo.commit of <git.repo.base.Repo '/global/homes/m/mek/MPAS/Components/src/Albany/.git'>>
>>> alb.head.commit
<git.Commit "a3435181289f1929243cac072caf8cf07b063acf">
>>> dir(alb.head.commit)
['Index', 'NULL_BIN_SHA', 'NULL_HEX_SHA', 'TYPES', '__class__', '__delattr__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattr__', '__getattribute__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__module__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__slots__', '__str__', '__subclasshook__', '_deserialize', '_get_intermediate_items', '_id_attribute_', '_iter_from_process_or_stream', '_process_diff_args', '_serialize', '_set_cache_', 'author', 'author_tz_offset', 'authored_date', 'authored_datetime', 'binsha', 'committed_date', 'committed_datetime', 'committer', 'committer_tz_offset', 'conf_encoding', 'count', 'create_from_tree', 'data_stream', 'default_encoding', 'diff', 'encoding', 'env_author_date', 'env_committer_date', 'gpgsig', 'hexsha', 'iter_items', 'iter_parents', 'list_items', 'list_traverse', 'message', 'name_rev', 'new', 'new_from_sha', 'parents', 'repo', 'size', 'stats', 'stream_data', 'summary', 'traverse', 'tree', 'type']
>>> alb.head.commit.message
'Add more documentation on the implementation of the gather evaluator of the solution and the parameter.\n'
>>> alb.head.commit.author
<git.Actor "kliegeois <kimliegeois@ymail.com>">
"""