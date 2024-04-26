<#
.SYNOPSIS
  This script will add an ICMP node to Orion.
.DESCRIPTION
  This script will call into the Orion API and add an ICMP only node. It creates the necessary pollers on the back end.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2022/APR/08
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
    $NodeIP = Read-Host "What is the IP/Hostname of the node that you would like to monitor? "
    $NodeName = Read-Host "What name do you want to call this node in SolarWinds? "

    #Build SW Information Service connection
    $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

    #Get Primary Orion Server Engine Info
    $swql = @" 
        SELECT TOP 1 
            EngineID
            ,ServerName
        FROM Orion.Engines 
        WHERE ServerType = 'Primary'
"@

    #Call into the Orion API to get data
    $OrionPrimaryEngine = Get-SwisData -SwisConnection $swis -Query $swql
    if ($null -eq $OrionPrimaryEngine -OR $OrionPrimaryEngine -eq "") {
        Throw "Unable to find the Orion Primary Polling EngineID..."
    }

    #Create blob of necessary info to pass into API.
    $newNodeProperties = @{
        IPAddress     = $NodeIP;
        EngineID      = $OrionPrimaryEngine.EngineID;
        Caption       = $NodeName;
        ObjectSubType = "ICMP";
        #DynamicIP     = "True";
        #DNS           = $NodeIP;
    }
    
    #Create new node
    $newNodeUri = New-SwisObject -SwisConnection $swis -EntityType "Orion.Nodes" -Properties $newNodeProperties

    #Query details about the new node
    $NodeDetails = Get-SwisObject -SwisConnection $swis -Uri $newNodeUri
    
    #Register specific pollers for the node
    $poller = @{
        NetObject     = "N:" + $NodeDetails["NodeID"];
        NetObjectType = "N";
        NetObjectID   = $NodeDetails["NodeID"];
    }
    
    #Poller: Status
    $poller["PollerType"] = "N.Status.ICMP.Native";
    New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller | Out-Null
    
    #Poller: Response time
    $poller["PollerType"] = "N.ResponseTime.ICMP.Native";
    New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller | Out-Null

    Write-Output "Created node: $($NodeDetails.Caption), IP Address: $($NodeDetails.IPAddress), Polling engine: $($OrionPrimaryEngine.ServerName)"
}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "ERROR: $Errormsg" 
}