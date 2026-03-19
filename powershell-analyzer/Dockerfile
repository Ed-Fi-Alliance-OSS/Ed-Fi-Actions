# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

# Do NOT use an Alpine image here, as the PowerShell script gets a stack overflow within the PSScriptAnalyzer module when running in an Alpine container. The LTS Ubuntu image does not have this issue.
FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04@sha256:663a172849444279d8e7b50e19977b6e42380eae6856bdc8931ca08e2e03e92a

COPY README.md /

COPY src/*.ps1 /src/
RUN ["pwsh", "-c", "Install-Module -Name PSScriptAnalyzer -Force -AllowClobber -Scope CurrentUser -Repository PSGallery -Confirm:$false"]

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "/src/entrypoint.ps1"]
