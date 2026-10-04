# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 7

<#
.DESCRIPTION
    This script runs PSScriptAnalyzer on an entire directory structure. When
    running inside GitHub Actions, findings are reported as inline workflow
    annotations and a job step summary. When run locally, findings are
    collected and printed as a table to the console (or, with
    -SaveToFile $false, streamed to the console as each file is analyzed).
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', 'unused', Justification = 'False positives')]
param (
    # Directory in which to do a recursive scan of PowerShell files
    [Parameter(Mandatory = $True)]
    [string]
    $Directory,

    # If set to $false, results stream directly to the console as each file
    # is analyzed instead of being collected and reported as a table /
    # GitHub Actions annotations.
    [boolean]
    $SaveToFile = $true,

    # List of excluded rules
    [string[]]
    $ExcludedRules = ""
)


<#
.DESCRIPTION
    Returns the path for the file under analysis
#>
function Get-Path {
    param (
        # An individual test result from running Invoke-ScriptAnalyzer
        [Parameter(Mandatory = $True)]
        [PSCustomObject]
        $analyzerResult
    )

    # Property ScriptPath returns the path where the file under analysis is located.
    # When running in GitHub Actions, this is relative to the server where the build is running
    # https://github.com/PowerShell/PSScriptAnalyzer/issues/1758#issuecomment-1006072757
    $path = $analyzerResult.ScriptPath

    $runningInGitHub = $env:GITHUB_ACTIONS -eq $true

    if ($runningInGitHub) {
        # Report the path relative to the checked-out repo so GitHub can
        # resolve it against the workflow run's annotations.
        return $path.replace('/github/workspace/testing-repo/', '')
    }
    else {
        return $path
    }
}

<#
.DESCRIPTION
    Maps PSScriptAnalyzer severity to the matching GitHub Actions workflow
    command (used for inline log annotations).
#>
function Get-AnnotationCommand {
    param (
        # An individual test result from running Invoke-ScriptAnalyzer
        [Parameter(Mandatory = $True)]
        [PSCustomObject]
        $analyzerResult
    )

    switch ($analyzerResult.Severity) {
        "Error" { return "error" }
        "Warning" { return "warning" }
        Default { return "notice" }
    }
}

<#
.DESCRIPTION
    Emits one GitHub Actions workflow command per finding so that each issue
    shows up as an inline annotation on the files changed / checks view,
    without touching Code Scanning / CodeQL.
    https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#setting-a-warning-message
#>
function Write-GitHubAnnotations {
    param (
        # Results returned by Invoke-ScriptAnalyzer
        [Parameter(Mandatory = $True)]
        [AllowEmptyCollection()]
        [array]
        $AnalyzerResults
    )

    foreach ($analyzerResult in $AnalyzerResults) {
        $line = $analyzerResult.Line
        if ($null -eq $line) { $line = 1 }
        $column = $analyzerResult.Column
        if ($null -eq $column) { $column = 1 }

        $command = Get-AnnotationCommand $analyzerResult
        $path = Get-Path $analyzerResult
        $message = $analyzerResult.Message -replace "`r`n|`n", " " -replace "%", "%25" -replace "`r", "%0D" -replace "`n", "%0A"

        Write-Output "::$command file=$path,line=$line,col=$column,title=$($analyzerResult.RuleName)::$message"
    }
}

<#
.DESCRIPTION
    Writes a Markdown summary of the findings to the GitHub Actions job
    summary ($GITHUB_STEP_SUMMARY), so that results are visible directly on
    the workflow run without opening an artifact or Code Scanning.
#>
function Write-GitHubStepSummary {
    param (
        # Results returned by Invoke-ScriptAnalyzer
        [Parameter(Mandatory = $True)]
        [AllowEmptyCollection()]
        [array]
        $AnalyzerResults
    )

    if ([string]::IsNullOrEmpty($env:GITHUB_STEP_SUMMARY)) {
        return
    }

    $lines = @("## PowerShell Analyzer Results", "")

    if ($AnalyzerResults.Count -eq 0) {
        $lines += "No issues found. :white_check_mark:"
    }
    else {
        $errorCount = ($AnalyzerResults | Where-Object { $_.Severity -eq "Error" }).Count
        $warningCount = ($AnalyzerResults | Where-Object { $_.Severity -eq "Warning" }).Count
        $infoCount = ($AnalyzerResults | Where-Object { $_.Severity -eq "Information" }).Count

        $lines += "Found $($AnalyzerResults.Count) issue(s): $errorCount error(s), $warningCount warning(s), $infoCount informational."
        $lines += ""
        $lines += "| Severity | Rule | File | Line | Message |"
        $lines += "| -------- | ---- | ---- | ---- | ------- |"

        foreach ($analyzerResult in $AnalyzerResults) {
            $line = $analyzerResult.Line
            if ($null -eq $line) { $line = 1 }
            $path = Get-Path $analyzerResult
            $message = $analyzerResult.Message -replace "\|", "\|" -replace "`r`n|`n|`r", " "

            $lines += "| $($analyzerResult.Severity) | $($analyzerResult.RuleName) | $path | $line | $message |"
        }
    }

    $lines | Out-File -FilePath $env:GITHUB_STEP_SUMMARY -Append -Encoding utf8
}

<#
.DESCRIPTION
    Run the PSScriptAnalyzer on a directory, reporting any findings either as
    GitHub Actions annotations/summary (when running in a workflow) or as a
    console table (when run locally).
#>
function Invoke-Analyzer {
    param (
        # Directory to scan
        [Parameter(Mandatory = $True)]
        [string]
        $Directory,

        [boolean]
        $SaveToFile,

        [string[]]
        $ExcludedRules = ""
    )

    if ($null -eq $(Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        # Install non-interactively inside containers. Use CurrentUser scope
        # and suppress confirmations to avoid hanging on prompts.
        try {
            Install-Module -Name PSScriptAnalyzer -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -Confirm:$false
        }
        catch {
            Write-Error "Failed to install PSScriptAnalyzer: $_"
            throw $_
        }
    }

    # Enumerate files individually rather than using -Recurse on the directory.
    # PSScriptAnalyzer can overflow the AST analysis call stack when scanning
    # complex scripts recursively. Running per-file avoids that.
    # See: https://github.com/PowerShell/PSScriptAnalyzer/issues/1807
    $psFiles = Get-ChildItem -Path $Directory -Recurse -Include "*.ps1", "*.psm1" -File

    $settings = @{
        ExcludeRules=@('PSUseSingularNouns', 'PSAvoidUsingWriteHost')
    }

    if ($SaveToFile) {
        $results = @($psFiles | ForEach-Object {
            Invoke-ScriptAnalyzer -Path $_.FullName -Settings $settings -ExcludeRule $ExcludedRules
        })
    }
    else {
        $psFiles | ForEach-Object {
            Invoke-ScriptAnalyzer -Path $_.FullName -Settings $settings -ExcludeRule $ExcludedRules -ReportSummary
        }
        return
    }

    if ($env:GITHUB_ACTIONS -eq $true) {
        Write-GitHubAnnotations -AnalyzerResults $results
        Write-GitHubStepSummary -AnalyzerResults $results
    }
    else {
        $results | Format-Table -Property RuleName, Severity, ScriptName, Line, Message -AutoSize
    }
}

if (-not (Test-Path $Directory)) {
    throw "Directory '$Directory' does not exist."
}

Write-Output "Begin analyzing all PowerShell files in $Directory..."

Invoke-Analyzer -Directory $Directory -SaveToFile $SaveToFile -ExcludedRules $ExcludedRules

Write-Output "Done with analysis of PowerShell files in $Directory."
exit(0)
