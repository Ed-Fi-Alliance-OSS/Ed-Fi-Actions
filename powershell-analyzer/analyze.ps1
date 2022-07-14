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
    # Directory in which to a recursive scan of PowerShell files
    [Parameter(Mandatory = $True)]
    [string]
    $Directory
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

    return $lang.Substring(5, 5)
}

<#
.DESCRIPTION
    Creates the outer "envelope" for Sarif test results.
#>
function Get-SarifContainer {
    return @{
        '$schema' = "http://json.schemastore.org/sarif-2.1.0-rtm.1"
        version   = "2.1.0"
        runs      = @(
            @{
                tool    = @{
                    driver = @{
                        name     = "PSScriptAnalyzer"
                        version  = (Find-Module PSScriptAnalyzer).Version
                        language = Get-Locale
                        rules    = @()
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
        $Directory
    )

    $results = Invoke-ScriptAnalyzer -Path $Directory

    # There is a bug that causes the PSScriptAnalyzer to fail to notice the use of $SarifData inside
    # of the ForEach-Object. And the recommended approach for suppressing messages is failing too.
    # Therefore, this has a dummy usage of the parameter just to satisfy the analyzer
    # https://github.com/PowerShell/PSScriptAnalyzer/issues/1472
    $SarifData | Out-Null

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
                            uri = (([system.uri]$_.ScriptPath).AbsoluteUri)
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

Invoke-Analyzer -Sarif $sarif -Directory .
Get-ChildItem -Path $Directory -Recurse -Directory | ForEach-Object {
    Invoke-Analyzer -Sarif $sarif -Directory $_
}

Invoke-PopulateRulesArray -Sarif $sarif

$sarif | ConvertTo-Json -Depth 10 | Out-File -Path results.sarif -Force
Write-Output "Done with analysis, see results.sarif for output."

