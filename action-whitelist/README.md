# action-whitelist
Scan `.github/workflows/` for `.yml files` and loop through all workflows, checking their versions against a list of approved authors and versions contained in `approved.json`.

The output is stored with the name `actions`, which can be retrieved in another action with `${{ steps.<step id>.outputs.actions }}`.

Used in lieu of Github Enterprise [Allow specified actions](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository#allowing-specific-actions-to-run) for private repositories.

## Example usage
Minimal uses expression to use this action:

``` yaml
uses: ./actions-whitelist
name: Scan used actions
id: scan-action
```
Note: this will check the current repo against the actions contained in `approved.json`

## Full example
This example shows how to use the action to get a json file with all the used actions in an organization. The json file is uploaded as an artefact in the third step.

|#|Name|Description|
|---|---|---|
|1|Load used actions|Run this action to load all actions used in an organization. Note the id of this step|
|2|Store json file|Output the json value from the output of the action in step 1, by using the id of step 1 in `${{ steps.<step id>.outputs.actions }}`|
|3|Upload result file as artefact|Upload the json file as an artefact|


``` yaml
jobs:
  load-all-used-actions:
    runs-on: ubuntu-latest
    steps: 
      - name: Checkout
        uses: actions/checkout@v2
      - uses: ./action-whitelist
        name: Scan used actions
        id: scan-action  
      - name: Upload result file as artifact
        uses: actions/upload-artifact@e448a9b857ee2131e752b06002bf0e093c65e571
        with: 
          name: actions
          path: ./actions.json
```

## Outputs
actions: a compressed json string with all the actions used in the workflows in the organization. The json is in the format:
``` json
[
    "actionLink": "actions/checkout",
    "actionVersion": "v2",
    "workflows": [
        {
            "repo": "Ed-Fi-Alliance-OSS/Ed-Fi-Actions/actions-whitelist",
            "workflowFileName": "action.yml"
        }
    ]
]
```
Properties:
|Name|Description|
|----|-----------|
|actionLink|The link to the action used in the workflow|
|actionVesion|The version of the action used in the workflow|
|workflows|An array of workflows that used the action|

The workflow object has the following properties:
|Name|Description|
|----|-----------|
|repo|The name of the repository that uses the action|
|workflowFileName|The name of the workflow file that was found in the directory `.github/workflows/`|