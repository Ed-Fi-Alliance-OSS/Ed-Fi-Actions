# Test Plan for `actions_parser` Script

## Introduction

This is a test plan that will be used to validate the functionality of the
`actions_parser` script. This script checks if the actions used in a repository
are approved, deprecated, or denied based on a predefined list of a approved
actions located in a `.json` file. The core requirements are outlined below
along with test cases and their expected behaviors.

## Core Requirements

1. **Load Approved Actions**: The script must load a JSON file containing the
   approved actions.
2. **Load Workflow Actions**: The script must load and parse YAML files from the
   specified workflow directory to identify used actions.
3. **Validate Actions**: The script must validate if the used actions are
   approved, deprecated, or denied based on the approved actions list.
4. **Logging and Output**: The script must log the results and output
   appropriate messages for approved, deprecated, and denied actions.

## Test Cases

### 1. Load Approved Actions

#### Happy Path

-   **Scenario**: The approved JSON file exists and is correctly formatted.
-   **Expected Behavior**: The script loads the file successfully and parses the
    content into a list of approved actions.

#### Failure Scenarios

-   **Scenario**: The approved JSON file does not exist.

    -   **Expected Behavior**: The script raises a `FileNotFoundError` and
        outputs an error message.

-   **Scenario**: The approved JSON file is incorrectly formatted.
    -   **Expected Behavior**: The script raises a `json.JSONDecodeError` and
        outputs an error message.

### 2. Load Workflow Actions

#### Happy Path

-   **Scenario**: The workflow directory contains valid YAML files with actions.
-   **Expected Behavior**: The script successfully loads and parses the YAML
    files, identifying all used actions.

#### Failure Scenarios

-   **Scenario**: The workflow directory does not exist.

    -   **Expected Behavior**: The script outputs a message indicating no
        workflow files were found.

-   **Scenario**: The YAML files are incorrectly formatted.
    -   **Expected Behavior**: The script outputs an error message for each
        malformed file and continues processing other files.

### 3. Validation of Actions

#### Happy Path

-   **Scenario**: All used actions are approved.
-   **Expected Behavior**: The script outputs a message indicating all actions
    are approved and exits with a status code of 0.

#### Failure Scenarios

-   **Scenario**: Some used actions are not approved.

    -   **Expected Behavior**: The script outputs a message listing the denied
        actions and exits with a status code of 1.

-   **Scenario**: Some used actions are deprecated.
    -   **Expected Behavior**: The script outputs a message listing the
        deprecated actions but continues to list them as approved.

### 4. Logging and Output

#### Happy Path

-   **Scenario**: The script processes actions as expected.
-   **Expected Behavior**: The script logs each action processed, including
    debug information for approved, deprecated, and denied actions.

#### Failure Scenarios

-   **Scenario**: The logging mechanism fails.
    -   **Expected Behavior**: The script continues processing actions but does
        not log messages.
