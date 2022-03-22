$env:PSModulePath += ":/root/.local/share/powershell/Modules"

try {
    Import-Module /src/powershell-yaml/ -Force
}
catch {
    Write-Warning "Error during importing of the yaml module needed for parsing"
    Write-Warning $_
}
