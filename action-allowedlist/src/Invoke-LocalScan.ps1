# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

<#
.SYNOPSIS
    Use for "localhost" execution of the approved Actions review.
#>

param(
    # The repository directory to scan
    [Parameter(Mandatory=$True)]
    [string]
    $RepoDirectory
)

Import-Module ./action-loader.psm1 -DisableNameChecking -Force
Import-Module ./allowed-action-analyzer.psm1 -DisableNameChecking -Force
Import-Module ./logging.psm1 -Force

$actionsFound = Get-AllUsedActions -RepoPath $RepoDirectory

$found = Invoke-ValidateActions -ActionsConfiguration $actionsFound -approvedPath "$($PSScriptRoot)/../approved.json"

Get-Log | ForEach-Object {
    Write-Output $_
}

if ($found) {
    exit 1
}

exit 0

