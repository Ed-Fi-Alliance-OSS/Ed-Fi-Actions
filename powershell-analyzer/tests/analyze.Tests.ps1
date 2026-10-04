# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

BeforeAll {
    # There is no action to take
}

Describe "when I run the PowerShell analyzer" {
    Context "given a directory that does not exist" {
        It "throws an error" {
            {
                Invoke-Expression "$PSScriptRoot/../src/analyze.ps1 -Directory does-not-exist"
            } | Should -Throw "Directory 'does-not-exist' does not exist."
        }
    }

    Context "given this test directory" {
        It "does not throw an error" {
            Invoke-Expression "$PSScriptRoot/../src/analyze.ps1 -Directory $PSScriptRoot"
        }
    }

    Context "when running in GitHub Actions" {
        BeforeEach {
            $script:PreviousGitHubActions = $env:GITHUB_ACTIONS
            $script:PreviousStepSummary = $env:GITHUB_STEP_SUMMARY
            $env:GITHUB_ACTIONS = "true"
            $analysisDirectory = Join-Path $TestDrive "analysis"
            New-Item -ItemType Directory -Path $analysisDirectory -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $analysisDirectory "sample.ps1") -Force | Out-Null
            $summaryPath = Join-Path $TestDrive "summary.md"
            Remove-Item -Path $summaryPath -Force -ErrorAction SilentlyContinue
            $analyzerScript = Join-Path $PSScriptRoot "../src/analyze.ps1"
            $env:GITHUB_STEP_SUMMARY = $summaryPath
        }

        AfterEach {
            $env:GITHUB_ACTIONS = $script:PreviousGitHubActions
            $env:GITHUB_STEP_SUMMARY = $script:PreviousStepSummary
        }

        It "maps severities and escapes workflow properties and Markdown table cells" {
            Mock Invoke-ScriptAnalyzer {
                @(
                    [PSCustomObject]@{
                        Severity = "Error"
                        RuleName = "Rule:One,Two"
                        ScriptPath = "/github/workspace/testing-repo/odd|path`ncomma,colon:percent%.ps1"
                        Line = 7
                        Column = 2
                        Message = "bad|100%`nnext line"
                    }
                    [PSCustomObject]@{
                        Severity = "Warning"
                        RuleName = "WarningRule"
                        ScriptPath = "/github/workspace/testing-repo/warning.ps1"
                        Line = 8
                        Column = 1
                        Message = "warning"
                    }
                    [PSCustomObject]@{
                        Severity = "Information"
                        RuleName = "InfoRule"
                        ScriptPath = "/github/workspace/testing-repo/info.ps1"
                        Line = 9
                        Column = 3
                        Message = "information"
                    }
                )
            }

            $output = Invoke-Expression "& '$analyzerScript' -Directory '$analysisDirectory'"

            $output | Should -Contain "::error file=odd|path%0Acomma%2Ccolon%3Apercent%25.ps1,line=7,col=2,title=Rule%3AOne%2CTwo::bad|100%25 next line"
            $output | Should -Contain "::warning file=warning.ps1,line=8,col=1,title=WarningRule::warning"
            $output | Should -Contain "::notice file=info.ps1,line=9,col=3,title=InfoRule::information"

            $summary = Get-Content -Path $summaryPath
            $summary | Should -Contain "Found 3 issue(s): 1 error(s), 1 warning(s), 1 informational."
            $summary | Should -Contain "| Error | Rule:One,Two | odd\|path comma,colon:percent%.ps1 | 7 | bad\|100% next line |"
        }

        It "reports when there are no findings" {
            Mock Invoke-ScriptAnalyzer { @() }

            $output = Invoke-Expression "& '$analyzerScript' -Directory '$analysisDirectory'"

            $output | Should -Not -Match "::(error|warning|notice)"
            Get-Content -Path $summaryPath | Should -Contain "No issues found. :white_check_mark:"
        }
    }
}
