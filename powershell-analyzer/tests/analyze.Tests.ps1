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
}
