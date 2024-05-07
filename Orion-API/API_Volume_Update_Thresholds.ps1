<#
.SYNOPSIS
  This script will update put nodes into maintenance mode/unmanage, for a user defined amount of time.
.DESCRIPTION
  Placing nodes into maintenance mode/unmanage is possible through the Orion Web Console. However, there are limitations 
  on filting for specific nodes. This script was created to use a custom SWQL query and then set the nodes returned into 
  an unmanaged state.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2023/APR/18
  Purpose/Change: Initial script development
  Website:        https://github.com/everychad/solarwinds
  Legal:          Scripts are not supported under any SolarWinds support program or service. Scripts are provided AS IS 
                  without warranty of any kind. SolarWinds further disclaims all warranties including, without limitation, 
                  any implied warranties of merchantability or of fitness for a particular purpose. The risk arising out 
                  of the use or performance of the scripts and documentation stays with you. In no event shall SolarWinds 
                  or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
                  damages whatsoever (including, without limitation, damages for loss of business profits, business 
                  interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
                  inability to use the scripts or documentation.   
  
.EXAMPLE
  None
#>
[CmdletBinding()]
param ()


<#----------------------------------------------------#>
<#------            Start of script              -----#>
<#----------------------------------------------------#>

try {
    #Check is the SolarWinds Powershell Module is installed.
    if (-not (Get-Module SwisPowerShell -ListAvailable)) {
        Throw 'Please install the SolarWindds PowerShell module first before running this script. It can be done in an elevated PowerShell console with: Install-Module -Name "SwisPowerShell"'
    }

    #Orion deployment connection Variables
    $OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
    $OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password: "

    #Build SW Information Service connection
    $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

    #Query Orion Nodes table
    $query = @"
        SELECT
              v.NodeID
              , v.Node.Caption AS [NodeName]
              , v.VolumeID
              , v.Caption AS [VolumeName]
              , t.Level1Value AS [WarningThreshold]
              , t.Level2Value AS [CriticalThreshold]
            , v.uri AS [uri]
        FROM Orion.Volumes v
        JOIN Orion.VolumesThresholds t 
            ON t.InstanceId = v.VolumeID
        WHERE v.VolumeID = '26'
"@
    #Call into Orion API
    $QueryData = Get-SwisData -SwisConnection $swis -Query $query

    #loop through all results returned by the query
    Foreach ($Volume in $QueryData) {

        Write-Output "Updating Warning Level threshold on volume: $($Volume.VolumeName) on $($Volume.NodeName)"
        #Uncomment when ready to push changes to Prod
        #Set-SwisObject $swis -Uri $Volume.uri -Properties @{ $Volume.Level1Value = '60'}
    }
}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "ERROR: $Errormsg"
}
