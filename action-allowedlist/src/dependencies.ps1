# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

$runningInGitHub = $env:GITHUB_ACTIONS -eq $true

try {

    if ($runningInGitHub) {
        $env:PSModulePath += ":/root/.local/share/powershell/Modules"
        Import-Module /src/powershell-yaml/ -Force
    }
    else {
        $env:PSModulePath += "$($PSScriptRoot)/../dep/powershell-yaml"
        Import-Module "$($PSScriptRoot)/../dep/powershell-yaml" -Force
    }
}
catch {
    Write-Warning "Error during importing of the yaml module needed for parsing"
    Write-Warning $_
}
