# SPDX-License-Identifier: Apache-2.0 Licensed to the Ed-Fi Alliance under one
# or more agreements. The Ed-Fi Alliance licenses this file to you under the
# Apache License, Version 2.0. See the LICENSE and NOTICES files in the project
# root for more information.

from actions_parser import get_all_used_actions, invoke_validate_actions
from pathlib import Path
import sys
from os.path import abspath


def main(workflow_directory: Path, approved_path: Path):
    print(f"Repository path to scan: {workflow_directory}")
    print(f"Approval file: {approved_path}")

    actions_found = get_all_used_actions(workflow_directory)

    found = invoke_validate_actions(approved_path, actions_found)

    if found:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    workflow_directory = Path(abspath(sys.argv[1]))
    approved_path = Path(abspath(sys.argv[2]))

    if workflow_directory is None or approved_path is None:
        raise RuntimeError(
            "Must specify the workflow directory and path to the approved file at the command line."
        )

    main(workflow_directory, approved_path)
