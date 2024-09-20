<#
.SYNOPSIS
  This script will add an ICMP node to Orion.
.DESCRIPTION
  This script will call into the Orion API and reset the ICMP pollers for a defined list of nodes.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2024/SEP/20
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
    #Orion deployment connection Variables
    $OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
    $OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password: "
    #$NodeIP = Read-Host "What is the NodeID of the node that you would like reset ICMP Pollers? "

    #Build SW Information Service connection
    $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

    #Get Primary Orion Server Engine Info
    $swql = @" 
        SELECT NodeID, Caption, uri
        FROM Orion.Nodes
        WHERE NodeID IN ('936')
"@

    #Call into the Orion API to get data
    $NodeResetList = Get-SwisData -SwisConnection $swis -Query $swql

    #Check that query returned data
    if ($null -eq $NodeResetList -OR $NodeResetList -eq "") {
        Throw "Unable to find any nodes with that query..."
    }
    
    #Query Poller URI
    $query = Get-SwisData -SwisConnection $swis -Query "SELECT URI, PollerType FROM Orion.Pollers where NetObjectID = $($NodeResetList.NodeID) and PollerType LIKE '%.ICMP.Native'"

    #Remove all entries of ICMP Poller
    ForEach ($entry in $query) {
        Write-Output "Removing $($entry.PollerType) pollers on $($NodeResetList.Caption)"
        Remove-SwisObject -SwisConnection $swis -Uri $entry.URI
    }
    
    $NodeDetails = Get-SwisObject -SwisConnection $swis -Uri $NodeResetList.uri
    #Register specific pollers for the node
    $poller = @{
        NetObject     = "N:" + $NodeDetails["NodeID"];
        NetObjectType = "N";
        NetObjectID   = $NodeDetails["NodeID"];
    }

    #readd all entries for ICMP Poller
    $pollertype = "N.Status.ICMP.Native","N.ResponseTime.ICMP.Native"
    ForEach ($entry in $pollertype) {
        $poller["PollerType"] = $entry;
        Write-Output "Adding poller $entry to $($NodeResetList.Caption)"
        New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller | Out-Null
    }
    
    Write-Output "Finished..."
}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "ERROR: $Errormsg" 
}