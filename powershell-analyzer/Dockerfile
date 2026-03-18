# SPDX-License-Identifier: Apache-2.0
# Licensed to the Ed-Fi Alliance under one or more agreements.
# The Ed-Fi Alliance licenses this file to you under the Apache License, Version 2.0.
# See the LICENSE and NOTICES files in the project root for more information.

FROM mcr.microsoft.com/powershell:alpine-3.17@sha256:4130d470c3e2735e88654e15e48db6464d173160f773275a7efbe3b974481aba

COPY README.md /

COPY src/*.ps1 /src/

ENTRYPOINT ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-File", "/src/entrypoint.ps1"]
