# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

function Invoke-ValidateActions {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [string]
        $approvedPath = "/src/approved.json",

        [Parameter()]
        [System.Object]
        $ActionsConfiguration
    )

    Write-InfoLog "Checking if used actions are approved"

    $approved = (Get-Content $approvedPath | ConvertFrom-Json -depth 10 | Select-Object actionLink, actionVersion, deprecated)
    $outputs = $ActionsConfiguration | Select-Object actionLink, actionVersion

    $numApproved = 0
    $numDenied = 0

    $unapprovedOutputs = @()
    $approvedOutputs = @()

    $found = $false

    foreach ($output in $outputs) {
        Write-DebugLog "Processing $($output.actionLink) version $($output.actionVersion)"

        $approvedOutputActionVersions = ($approved | Where-Object actionLink -eq $output.actionLink)
        if ($approvedOutputActionVersions) {
            Write-DebugLog "Approved Versions for $($output.actionLink): $($approvedOutputActionVersions.actionVersion)"
        }
        else {
            Write-DebugLog "No Approved versions for $($output.actionLink) were found."
        }

        $approvedOutput = $approvedOutputActionVersions `
            | Where-Object actionVersion -eq $output.actionVersion

        if ($approvedOutput) {
            Write-DebugLog "Output versions approved: $approvedOutput"
            $approvedOutputs += $approvedOutput
            $numApproved++

            # Look for deprecation
            if ($approvedOutput.deprecated -eq $True) {
                Write-WarnLog "Using a deprecated version of $($output.actionLink)"
            }
        }
        else {
            Write-DebugLog "Output versions not approved: $($output.actionLink) version $($output.actionVersion)"

            $unapprovedOutputs += "$($output.actionLink) $($output.actionVersion)"
            $numDenied++
        }
    }

    if ($numDenied -gt 0) {
        $e = "The following $numDenied actions/versions were denied: "
        $unapprovedOutputs | ForEach-Object {
            $e += "$($_); "
        }
        Write-ErrLog $e
        $found = $True
    }
    else {
        Write-InfoLog "All $numApproved actions/versions are approved."
    }

    $found
}
