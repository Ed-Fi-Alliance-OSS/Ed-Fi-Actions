FROM mcr.microsoft.com/powershell

COPY /src/*.ps*1 /src/
COPY ./dep/powershell-yaml/ /src/powershell-yaml/
COPY *approved.json /src/approved.json
#RUN pwsh -command "Install-Module powershell-yaml -Force"

ENTRYPOINT ["pwsh", "/src/entrypoint.ps1"]
