# action-allowedlist

Scan `.github/workflows/` for `.yml files` and loop through all workflows, checking their versions against a list of approved authors and versions contained in `approved.json`

Used in lieu of Github Enterprise [Allow specified actions](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-specific-actions-to-run) for private repositories.

## Example usage

Minimal uses expression to use this action:

``` yaml
- uses: ./actions-allowedlist
  name: Scan used actions
  id: scan-action
```

Note: this will check the current repo against the actions contained in `approved.json`.

Example for calling this action from a different repository:

```yml
- uses: Ed-Fi-Alliance-OSS/Ed-Fi-Actions/action-allowedlist@latest
  name: Scan used actions
  id: scan-action
```

❗ In this one case, it is appropriate to use a tag ("latest") instead of a commit hash. Otherwise
we have a chicken-and-egg problem: the approved list of actions would need to know the has for
the commit that saves the update to the action.

## Full example

This example shows how to use the action to get a json file with all the used actions in an organization. The json file is uploaded as an artefact in the third step.

``` yaml
jobs:
  load-all-used-actions:
    runs-on: ubuntu-latest
    steps: 
      - name: Checkout
        uses: actions/checkout@v2
      - uses: ./action-allowedlist
        name: Scan used actions
        id: scan-action  
      - name: Upload result file as artifact
        uses: actions/upload-artifact@e448a9b857ee2131e752b06002bf0e093c65e571
        with: 
          name: actions
          path: ./actions.json
```

## Outputs

actions: a json string with all the unapproved actions used in the workflows in the repo. The json is in the format:

``` json
[
  {
    "actionLink": "actions/checkout",
    "actionVersion": "v2"
  }
]
```

Properties:
|Name|Description|
|----|-----------|
|actionLink|The link to the action used in the workflow|
|actionVersion|The version of the action used in the workflow|
