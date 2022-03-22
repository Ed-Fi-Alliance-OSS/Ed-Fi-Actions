Import-Module /src/action-whitelist.psm1 -DisableNameChecking

$actionsFound = LoadAllUsedActions -RepoPath $pwd
$unapproved = CheckIfActionsApproved -outputs $actionsFound
$jsonObject = ($unapproved | ConvertTo-Json)
$jsonObject | out-file ./actions.json
Write-Output "::set-output name=actions::'$jsonObject'"
#Write-Host "Stored actions in outputs list. Use $${{ steps.<step id>.outputs.actions }} in next action to load the json"

if ($unapproved.Count -gt 0) {
    Write-Error "Repo contains unapproved actions!"
    exit 1
}else{
    #Write-Host "All actions were approved!"
    exit 0
}