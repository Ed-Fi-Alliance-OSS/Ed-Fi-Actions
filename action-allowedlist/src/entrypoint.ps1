Import-Module /src/action-allowedlist.psm1 -DisableNameChecking

$actionsFound = LoadAllUsedActions -RepoPath $pwd
$unapproved = CheckIfActionsApproved -outputs $actionsFound
$jsonObject = ($unapproved | ConvertTo-Json)
$jsonObject | out-file ./actions.json
Write-Output "::set-output name=actions::'$jsonObject'"

if ($unapproved.Count -gt 0) {
    Write-Error "Repo contains unapproved actions!"
    exit 1
}else{
    #Write-Host "All actions were approved!"
    exit 0
}