param( 
    [string] $RepoPath = "/github/workspace",
    [string] $whitelist = "/src/approved.json"
)
# pull in central calls script
. $PSScriptRoot\generic.ps1
if( $ENV:whitelist ) {
    $approvedPath = $ENV:whitelist
}else{
    $approvedPath = $whitelist
}

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
    $workflowFiles = gci "/github/workspace/.github/workflows" | Where {$_.Name.EndsWith(".yml")}
    if ($workflowFiles.Count -lt 1) {
        Write-Host "Could not find workflow files in $RepoPath"
        return;
    }
    
    # create a hastable to store the list of files in
    $actionsInRepo = @()

    Write-Host "Found [$($workflowFiles.Count)] files in the workflows directory"
    foreach ($workflowFile in $workflowFiles) {
        try {
            if ($workflowFile.FullName.EndsWith(".yml")) { 
                $workflow = gc $workflowFile.FullName -Raw
                $actions = GetActionsFromFile -workflow $workflow -workflowFileName $workflowFile.FullName

                $actionsInRepo += $actions
            }
        }
        catch {
            Write-Warning "Error handling this workflow file:"
            Write-Host (gc $workflowFiles[0].FullName -raw) | ConvertFrom-Json -Depth 10
            Write-Warning "----------------------------------"
            Write-Host "Error: [$_]"
            Write-Warning "----------------------------------"
        }
    }

    return $actionsInRepo
}

function SummarizeActionsUsed {
    param (
        [object] $actions
    )

    $summarized =  @()
    foreach ($action in $actions) {
        $found = $summarized | Where-Object { $_.actionVersion -eq $action.actionVersion }
        if ($null -ne $found) {
            # action already found, add this info to it
            $newInfo =  [PSCustomObject]@{
                workflowFileName = $action.workflowFileName
            }

            $found.workflows += $newInfo
            $found.count++
        }
        else {
            # new action, create a new object
            $newItem =  [PSCustomObject]@{
                actionLink = $action.actionLink
                actionVersion = $action.actionVersion
                count = 1
                workflows =  @(
                    [PSCustomObject]@{
                        workflowFileName = $action.workflowFileName
                    }
                )           
            }
            $summarized += $newItem
        }
    }

    return $summarized
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
        [Parameter(Mandatory=$true)]
        [string]
        $approvedPath,
        [Parameter(Mandatory=$true)]
        [string]
        $outputPath
    )

    $approved = (gc $approvedPath | convertfrom-Json -depth 10 | select  actionLink, actionVersion)

    $outputs = (gc $outputPath | convertfrom-Json -depth 10 | select  actionLink, actionVersion)

    $numApproved = 0
    $numDenied = 0

    $unapprovedOutputs = @()
    $approvedOutputs = @()

    foreach($output in $outputs){
        Write-Verbose "Processing $($output.actionLink) version $($output.actionVersion)"

        $approvedOutputActionVersions = ($approved | where actionLink -eq $output.actionLink)
        if ($approvedOutputActionVersions) {
            Write-Verbose "Approved Versions for $($output.actionLink) : "
            $approvedOutputActionVersions.actionVersion
        }else{
            Write-Verbose "No Approved versions for $($output.actionLink) were found. "
            
        }
        

        $approvedOutput = $approvedOutputActionVersions| where actionVersion -eq $output.actionVersion
        
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
        Write-Error "The following $numDenied actions/versions were denied!"
        return $unapprovedOutputs

    }else{
        Write-Host "All $numApproved actions/versions were approved!"
    }

}

function main() {

    # Find the current root of the repo
    #$RepoPath = "/github/workspace"

    # get actions from the workflows in the repos
    $actionsFound = LoadAllUsedActions RepoPath $RepoPath

    if ($actionsFound.Count -gt 0) {
                
        $summarizeActions = SummarizeActionsUsed -actions $actionsFound

        Write-Host "Found [$($actionsFound.Count)] actions used in workflows with [$($summarizeActions.Count) unique actions]"

        # write the actions to disk
        $fileName = "summarized-actions.json"
        $jsonObject = ($summarizeActions | ConvertTo-Json -Depth 10)
        New-Item -Path $fileName -Value $jsonObject -Force | Out-Null
        #Write-Host "Stored the summarized usage info into this file: [$fileName]"

        # JAR TODO: 
        $scannedActions = CheckIfActionsApproved -approvedPath $approvedPath -outputPath $fileName
    }

    #return $summarizeActions
    return $scannedActions
}

$actions = main
return $actions