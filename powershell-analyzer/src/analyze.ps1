# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

#Requires -Version 7

<#
.DESCRIPTION
    This script runs PSScriptAnalyzer on an entire directory structure, and
    outputs the results as a Sarif file. This file can be read directly (it is
    in JSON), or opened in Visual Studio Code with the sarif extension, or it
    can be uploaded into GitHub Code QL results.
#>
param (
    # Directory in which to do a recursive scan of PowerShell files
    [Parameter(Mandatory = $True)]
    [string]
    $Directory,

    # If set to $false, it will only print the results.
    [boolean]
    $SaveToFile = $true,

    # Location of the results file
    [string]
    $ResultsPath = "results.sarif",

    # List of excluded rules
    [string[]]
    $ExcludedRules = ""
)


<#
.DESCRIPTION
    Translate the severity reported by PSScriptAnalyzer into one of the four
    levels acceptable in a Sarif file.
#>
function Get-Severity {
    param (
        # An individual test result from running Invoke-ScriptAnalyzer
        [Parameter(Mandatory = $True)]
        [PSCustomObject]
        $analyzerResult
    )

    switch ($analyzerResult.Severity) {
        "Error" { return "error" }
        "Warning" { return "warning" }
        "Information" { return "note" }
        Default { return "none" }
    }
}

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
        #Allows CodeQL to show preview of the file
        return $path.replace('/github/workspace/testing-repo/', '')
    } else {
        return $path
    }
}

<#
.DESCRIPTION
    A Sarif file needs to have a locale in order for GitHub CodeQL to accept it.
    How we determine the locale depends on our operating system. In some cases,
    it won't even be set at the operating system level. If not set, just default
    to "en-US".
#>
function Get-Locale {
    if ($IsWindows) {
        return (Get-WinSystemLocale).Name
    }

    $lang = (locale) -split "\n" | Where-Object { $_.startsWith("LANG=") }
    # example: LANG=en_US.UTF-8

    if ($lang.Length -eq 0) {
        return "en-US"
    }

    return $lang.Substring(5, 5).replace('_', '-')
}

<#
.DESCRIPTION
    Creates the outer "envelope" for Sarif test results.
#>
function Get-SarifContainer {
    return @{
        '$schema' = "http://json.schemastore.org/sarif-2.1.0"
        version   = "2.1.0"
        runs      = @(
            @{
                tool    = @{
                    driver = @{
                        name           = "PSScriptAnalyzer"
                        version        = (Find-Module PSScriptAnalyzer).Version
                        language       = Get-Locale
                        informationUri = "https://docs.microsoft.com/en-us/powershell/module/psscriptanalyzer"
                        rules          = @()
                    }
                }
                results = @()
            }
        )
    }
}

<#
.DESCRIPTION
    Run the PSScriptAnalyzer on a directory, adding the results into the given
    $Sarif object.
#>
function Invoke-Analyzer {
    param (
        # Pre-created Sarif results object
        [Parameter(Mandatory = $True)]
        [PSCustomObject]
        $SarifData,

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
        Install-Module -Name PSScriptAnalyzer -Force
    }

    # There is a bug that causes the PSScriptAnalyzer to fail to notice the use of $SarifData inside
    # of the ForEach-Object. And the recommended approach for suppressing messages is failing too.
    # Therefore, this has a dummy usage of the parameter just to satisfy the analyzer
    # https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
    $SarifData | Out-Null

    if($SaveToFile) {
        $results = Invoke-ScriptAnalyzer -Path $Directory -ExcludeRule $ExcludedRules -Recurse
    } else {
        Invoke-ScriptAnalyzer -Path $Directory -ExcludeRule $ExcludedRules -Recurse -ReportSummary
        return
    }

    $results | ForEach-Object {
        $SarifData.runs[0].results += @{
            ruleId    = $_.RuleName
            level     = Get-Severity $_
            message   = @{
                text = $_.Message
            }
            locations = @(
                @{
                    physicalLocation = @{
                        artifactLocation = @{
                            uri = Get-Path $_
                        }
                        region           = @{
                            startLine   = $_.Line
                            startColumn = $_.Column
                        }
                    }
                }
            )
        }
    }
}

<#
.DESCRIPTION
    Reads all the rules actually reported on by the scans, and load the unique
    rules into the tool.driver.rules array.
#>
function Invoke-PopulateRulesArray {
    param (
        # Pre-created Sarif results object
        [Parameter(Mandatory = $True)]
        [PSCustomObject]
        $SarifData
    )

    $SarifData.runs[0].results | Select-Object -ExpandProperty ruleId | Sort-Object | Get-Unique | ForEach-Object {
        $rule = Get-ScriptAnalyzerRule $_

        $SarifData.runs[0].tool.driver.rules += @{
            id               = $_
            shortDescription = @{
                text = $rule.CommonName
            }
            fullDescription  = @{
                text = $rule.Description
            }
            helpUri          = "https://docs.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/rules/$($_.ToString().Substring(2))"
            properties       = @{
                tags = @(
                    "PowerShell"
                )
            }
        }
    }
}

Write-Output "Begin analyzing all PowerShell files in the specified directory tree..."

$sarif = Get-SarifContainer

Invoke-Analyzer -Sarif $sarif -Directory $Directory -SaveToFile $SaveToFile -ExcludedRules $ExcludedRules

if($SaveToFile) {
    Invoke-PopulateRulesArray -Sarif $sarif
    $sarif | ConvertTo-Json -Depth 10 | Out-File -Path $ResultsPath -Force
    Write-Output "Done with analysis, see $ResultsPath for output."
} else {
    Write-Output "Done with analysis."
}
