# pull in central calls script
. $PSScriptRoot\dependencies.ps1

# Parse yaml file and return a hashtable with actionLink, actionVersion, and workFlowFileName
function GetActionsFromFile {
    param (
        [string] $workflow,
        [string] $workflowFileName
    )

    # Parse the file and extract the actions used in it
    # NOTE: This needs module powershell-yaml
    $parsedYaml = ConvertFrom-Yaml $workflow

    # create a hastable
    $actions = @()

    # go through the parsed yaml
    foreach ($job in $parsedYaml["jobs"].GetEnumerator()) {
        Write-Host "  Job found: [$($job.Key)]"
        $steps=$job.Value.Item("steps")
        foreach ($step in $steps) {
            $uses=$step.Item("uses")
            if ($null -ne $uses) {
                Write-Host "   Found action used: [$uses]"
                $actionLink = $uses.Split("@")[0]
                $actionVersion = $uses.Split("@")[1]

                $data = [PSCustomObject]@{
                    actionLink = $actionLink
                    actionVersion = $actionVersion
                    workflowFileName = $workflowFileName
                }

                $actions += $data
            }
        }
    }

    return $actions
}


function GetAllUsedActions {
    param (
        [string] $RepoPath = "/github/workspace"
    )

    # get all the actions from the repo
    $workflowFiles = Get-ChildItem "$($RepoPath)/.github/workflows" | Where {$_.Name.EndsWith(".yml")}
    if ($workflowFiles.Count -lt 1) {
        Write-Host "Could not find workflow files in the current directory"
        return;
    }
    
    # create a hastable to store the list of files in
    $actionsInRepo = @()

    Write-Host "Found [$($workflowFiles.Count)] files in the workflows directory"
    foreach ($workflowFile in $workflowFiles) {
        try {
            if ($workflowFile.FullName.EndsWith(".yml")) { 
                $workflow = Get-Content $workflowFile.FullName -Raw
                $actions = GetActionsFromFile -workflow $workflow -workflowFileName $workflowFile.FullName

                $actionsInRepo += $actions
            }
        }
        catch {
            Write-Warning "Error handling this workflow file:"
            Write-Host (Get-Content $workflowFiles[0].FullName -raw) | ConvertFrom-Json -Depth 10
        }
    }

    return $actionsInRepo
}

function LoadAllUsedActions {
    param (
        [string] $RepoPath = "/github/workspace"
    )
    # create hastable
    $actions = @()

    Write-Host "Loading actions..."
    $actionsUsed = GetAllUsedActions -RepoPath $RepoPath
    $actions += $actionsUsed

    return $actions
}

function CheckIfActionsApproved {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $approvedPath = "/src/approved.json",
        $outputs
    )

    $approved = (Get-Content $approvedPath | convertfrom-Json -depth 10 | select  actionLink, actionVersion)

    $outputs = $outputs | select  actionLink, actionVersion

    $numApproved = 0
    $numDenied = 0

    $unapprovedOutputs = @()
    $approvedOutputs = @()

    foreach($output in $outputs){
        Write-Verbose "Processing $($output.actionLink) version $($output.actionVersion)"

        $approvedOutputActionVersions = ($approved | where actionLink -eq $output.actionLink)
        if ($approvedOutputActionVersions) {
            Write-Verbose "Approved Versions for $($output.actionLink) : "
            Write-Verbose "$($approvedOutputActionVersions.actionVersion)"
        }else{
            Write-Verbose "No Approved versions for $($output.actionLink) were found. "
            
        }
        

        $approvedOutput = $approvedOutputActionVersions | where actionVersion -eq $output.actionVersion | Where {$_.actionVersion -eq $output.actionVersion}
        
        if ($approvedOutput) {
            Write-Verbose "Output versions approved: $approvedOutput"
            $approvedOutputs += $approvedOutput
            $numApproved++
        }else {
            Write-Verbose "Output versions unapproved: $($output.actionLink) version $($output.actionVersion)"
            $unapprovedOutputs += $output
            $numDenied++
        }

    }

    if ($unapprovedOutputs.Count -gt 0) {
        Write-Host "The following $numDenied actions/versions were denied!"
        Write-Host $unapprovedOutputs
        return $unapprovedOutputs

    }else{
        Write-Host "All $numApproved actions/versions were approved!"
    }

}
