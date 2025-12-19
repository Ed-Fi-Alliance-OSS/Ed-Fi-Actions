# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

import json
import yaml
from pathlib import Path


def load_json_file(filepath):
    with open(filepath, "r") as file:
        content = file.read()
        return json.loads(content)


def load_yaml_file(filepath):
    with open(filepath, "r") as file:
        return yaml.safe_load(file)


def get_actions_from_file(workflow, workflow_file_name):
    parsed_yaml = yaml.safe_load(workflow)
    actions = []

    for job_name, job in parsed_yaml.get("jobs", {}).items():
        print(f"  Job found: [{job_name}] in {workflow_file_name}")
        steps = job.get("steps", [])
        for step in steps:
            uses = step.get("uses")
            if uses is not None:
                parts = uses.split("@")
                if len(parts) == 2:
                    action_link, action_version = parts
                    actions.append(
                        {
                            "actionLink": action_link,
                            "actionVersion": action_version,
                            "workflowFileName": workflow_file_name,
                        }
                    )
                    print(f"   Found action used: [{uses}]")

    return actions


def get_all_used_actions(workflow_dir: Path):
    print("Loading Actions YAML files")
    if (workflow_dir / ".github/workflows").exists():
        workflow_files = list((workflow_dir / ".github/workflows").glob("*.yml"))
    else:
        workflow_files = list(
            (workflow_dir / "testing-repo/.github/workflows").glob("*.yml")
        )
    if not workflow_files:
        print("Could not find workflow files in the specified directory")
        return []

    print(f"Found [{len(workflow_files)}] files in the workflows directory")

    actions_in_repo = []

    for workflow_file in workflow_files:
        try:
            workflow_content = workflow_file.read_text()
            actions = get_actions_from_file(workflow_content, workflow_file.name)
            actions_in_repo.extend(actions)
        except Exception as e:
            print(f"Error occurred while reading {workflow_file}: {e}")

    return actions_in_repo


def invoke_validate_actions(approved_path, actions_configuration):
    print("Checking if used actions are approved")

    approved = load_json_file(approved_path)
    num_approved = 0
    num_denied = 0
    num_deprecated = 0
    unapproved_outputs = []
    approved_outputs = []
    found = False

    for action in actions_configuration:
        print(
            f"::debug::Processing {action['actionLink']} version {action['actionVersion']}"
        )

        # Auto-approve any github/* or actions/* actions
        if action["actionLink"].startswith("github/") or action[
            "actionLink"
        ].startswith("actions/"):
            action_type = (
                "github" if action["actionLink"].startswith("github/") else "actions"
            )
            print(
                f"::debug::Auto-approving {action_type} action: {action['actionLink']}"
            )
            approved_outputs.append(
                {
                    "actionLink": action["actionLink"],
                    "actionVersion": action["actionVersion"],
                    "deprecated": False,
                }
            )
            num_approved += 1
            continue

        # Find the action entry in approved list (new structure)
        approved_action_entry = None
        for approved_entry in approved:
            if approved_entry["actionLink"] == action["actionLink"]:
                approved_action_entry = approved_entry
                break

        if approved_action_entry:
            # Extract all versions for this action
            approved_versions = approved_action_entry.get("versions", [])
            version_list = [v["version"] for v in approved_versions]
            print(
                f"::debug::Approved Versions for {action['actionLink']}: {version_list}"
            )

            # Find matching version
            approved_version = None
            for v in approved_versions:
                if v["version"] == action["actionVersion"]:
                    approved_version = v
                    break

            if approved_version:
                print(f"::debug::Output versions approved: {approved_version}")
                approved_outputs.append(
                    {
                        "actionLink": action["actionLink"],
                        "actionVersion": action["actionVersion"],
                        "deprecated": approved_version.get("deprecated", False),
                    }
                )
                num_approved += 1

                # Look for deprecation
                if approved_version.get("deprecated", False):
                    print(f"Using a deprecated version of {action['actionLink']}")
                    num_deprecated += 1
            else:
                print(
                    f"::debug::Output versions not approved: {action['actionLink']} version {action['actionVersion']}"
                )
                unapproved_outputs.append(
                    f"{action['actionLink']} {action['actionVersion']}"
                )
                num_denied += 1
                found = True
        else:
            print(
                f"::debug::No Approved versions for {action['actionLink']} were found."
            )
            unapproved_outputs.append(
                f"{action['actionLink']} {action['actionVersion']}"
            )
            num_denied += 1
            found = True

    if num_denied > 0:
        e = f"The following {num_denied} actions/versions were denied: {', '.join(unapproved_outputs)}"
        print(f"::error file=actions_parser.py,title=Denied Actions::{e}")
        return found
    else:
        print(f"All {num_approved} actions/versions are approved.")
        if num_deprecated > 0:
            e = f"Deprecated actions found: {num_deprecated}"
            print(f"::warning file=actions_parser.py,title=Deprecated Actions::{e}")
        return found
