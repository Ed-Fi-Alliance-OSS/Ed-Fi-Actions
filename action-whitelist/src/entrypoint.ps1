param (
    [string] $RepoPath = "/github/workspace",
    [string] $whitelist = "/src/approved.json"
)

function Get-LocationInfo {
    Write-Host "Where are we? [$pwd]"

    ForEach ($file in Get-ChildItem) {
        Write-Host "- $($file.Name)"
    }
}

function main {

    $actions = (.\action-whitelist.ps1 -RepoPath $RepoPath -whitelist $whitelist)

    # wite the file outside of the container so we can pick it up
    #Write-Host "Found [$($actions.Count)] actions "
    #Write-Verbose $actions | ConvertTo-Json -Depth 10
    $jsonObject = ($actions | ConvertTo-Json -Depth 10 -Compress)
    $jsonObjectPretty = ($actions | ConvertTo-Json -Depth 10)
    $jsonPath = "/actions/actions.json"
    if (! (Test-Path $jsonPath)) {
        $jsonPath = "$PSScriptRoot/actions.json"
    }

    $jsonObjectPretty | Out-File -FilePath $jsonPath
    #Write-Output "::set-output name=actions::'$jsonObject'"
    #Write-Host "Stored actions in outputs list. Use $${{ steps.<step id>.outputs.actions }} in next action to load the json"
}

try {
    # always run in the correct location, where our scripts are located:
    Set-Location $PSScriptRoot

    # call main script:
    main

    # return the container with the exit code = Ok:    
    exit 0
}
catch {
    # return the container with the last exit code: 
    Write-Error "Error loading the actions:"
    Write-Error $_
    # return the container with an erroneous exit code:
    exit 1
}