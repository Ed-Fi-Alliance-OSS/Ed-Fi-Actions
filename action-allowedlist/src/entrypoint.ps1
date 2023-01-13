# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

Import-Module /src/action-loader.psm1 -DisableNameChecking
Import-Module /src/allowed-action-analyzer.psm1 -DisableNameChecking
Import-Module /src/logging.psm1

$actionsFound = Get-AllUsedActions -RepoPath $pwd

$found = Invoke-ValidateActions -ActionsConfiguration $actionsFound -approvedPath "/src/approved.json"

Get-Log | ForEach-Object {
    Write-Output $_
}

if ($found) {
    exit 1
}

exit 0
