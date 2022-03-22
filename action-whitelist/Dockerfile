FROM mcr.microsoft.com/powershell

COPY /src/*.ps1 /src/
COPY /src/*.psm1 /src/
COPY *approved.json /src/approved.json
RUN pwsh -command "Install-Module powershell-yaml -Force"

ENTRYPOINT ["pwsh", "/src/entrypoint.ps1"]
