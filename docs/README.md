# Bidirectional and Allowed Action repository scanning

Scans a repo for hidden unicode bidirectional characters as described in
CVE-2021-42694 and detailed at https://trojansource.codes/

This action is paired with the Ed-Fi allowed action scanner as described in [this
readme](../action-allowedlist)

## Example usage

Minimal 'uses' expression to use this action:

``` yaml
- uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml
```

Note: adding the above to an existing workflow will call both the allowed action
and bidi scanner on the existing repo


```yml
name: Run Unicode Bidirectional Character Scan

on:
  push:
    branches:
      - '**'

jobs:
   scan-repo:
    uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/repository-scanner.yml

```
Above is a complete action that once included in the /.github/workflows will
checkout and scan the current repo for allowed actions and bidirectional
characters

## Outputs
### bidi-scanner
If no hidden control characters were found the action will return 'No Errors
Found.' and the job will pass. If hidden control characters are found an error
similar to the following will be shown and the job will fail

```
Error: bidirectional control character: Right-to-Left Embedding control character
bidirectional control character in Extensions/bidirectional_characters_test.cs line 1 column 10 (Right-to-Left Embedding control character)
```

### AllowedList
actions: a json string with all the unapproved actions used in the workflows in
the repo. The json is in the format:

``` json
[
  {
    "actionLink": "actions/checkout",
    "actionVersion": "v2"
  }
]
```

Properties: 

| Name          | Description                                    |
| ------------- | ---------------------------------------------- |
| actionLink    | The link to the action used in the workflow    |
| actionVersion | The version of the action used in the workflow |


## Bidi Scanner Only
We have also provided an action for bidi scanning seperate from the allowed
action scanning, using the following yaml:

```
- uses: ed-fi-alliance-oss/ed-fi-actions/.github/workflows/bidi-scanner.yml
```
