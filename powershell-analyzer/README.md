# powershell-analyzer

Lint PowerShell scripts and modules using
[PSScriptAnalyzer](https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer).
This can be run locally or executed in GitHub Actions.

## Run Locally

``` pwsh
.\analyze.ps1 -Directory /folder-or-file
```

Options:

| Parameter     | Description                                                                                                                                                       |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Directory     | Folder or Path to run analysis against. Required.                                                                                                                 |
| SaveToFile    | Save to file, or print to console. Default: Save to file                                                                                                          |
| ResultsPath   | Path to save the results. Default "./results.sarif"                                                                                                               |
| IncludedRules | List of rules that should be included to analysis.       |
| ExcludedRules | List of rules that should be excluded from analysis.     |

[List of available
rules](https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules)

### Result Formats

- [SARIF](https://sarifweb.azurewebsites.net/) reports
- Print to console

Example running locally printing to console:

``` pwsh
.\analyze.ps1 -Directory /folder -SaveToFile $False
```

Result:

| RuleName                | Severity | ScriptName  | Line | Message |
| ----------------------- | -------- | ----------- | ---- | ------- |
| PSReviewUnusedParameter | Warning  | analyze.ps1 | 15   | Output  |

## Run with Docker

Build the image and run the container to scan a directory (the container's entrypoint runs the bundled `analyze.ps1`).

PowerShell (Windows):

```powershell
docker build -t powershell-analyzer:local .
docker run --rm -v ${PWD}:/workspace powershell-analyzer:local /workspace/src
```

Bash / macOS / Linux:

```bash
docker build -t powershell-analyzer:local .
docker run --rm -v "$(pwd)":/workspace powershell-analyzer:local /workspace/src
```

Notes:

- Do not mount over the container's `/src` directory (it contains the analyzer script). Mount your repository (or target folder) to another path like `/workspace` and pass `/<path>/src` as the argument so the built-in entrypoint can run `/src/analyze.ps1` with the correct target directory.
- The example scans the `src` directory in your repository; adjust the mounted path and argument to scan a different folder.

## Run in GitHub Actions

Include into your workflow file:

``` yaml
    name: Linter
    uses: Ed-Fi-Alliance-OSS/Ed-Fi-Actions/.github/workflows/powershell-analyzer.yml@latest
```

This will automatically analyze all the PowerShell scripts and modules in the
repo. Since this is a linter, not a security scanner, results are surfaced
without using Code Scanning / CodeQL:

- **Inline log annotations**: each finding is emitted as a `::warning`,
  `::error`, or `::notice` workflow command, so it shows up annotated on the
  workflow run (and on the affected lines, when the file is part of the
  checked-out repo).
- **Job summary**: a Markdown table of all findings (severity, rule, file,
  line, message) is written to the workflow run's summary page.
- **SARIF artifact**: the full SARIF report is still generated and uploaded
  as a build artifact (`analysis-result`) for deeper inspection or import
  into other tools (e.g. the SARIF VS Code extension), but it is no longer
  uploaded to Code Scanning.

## See it in action

[powershell-analyzer.yml](https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Actions/blob/main/.github/workflows/powershell-analyzer.yml)
is invoked by
[on-pullrequest-powershell.yml](https://github.com/Ed-Fi-Alliance-OSS/Ed-Fi-Actions/blob/main/.github/workflows/on-pullrequest-powershell.yml)
on every pull request touching PowerShell files. You can manually trigger the
workflow or review the annotations and job summary on the corresponding
workflow run.
