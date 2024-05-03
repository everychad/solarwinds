<#
.SYNOPSIS
  This script will move an agent node from one polling engine to another.
.DESCRIPTION
  This script will call into the Orion API and move a group of agent nodes from one engine to another. You will need to 
  update the SWQL ($query) to only capture the nodes you wish to migrate. You will also need to know the EngineID of the
  Polling engine you wish to migrate nodes to.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2024/MAY/03
  Purpose/Change: Initial script development
  Website:        https://thwack.solarwinds.com/content-exchange/the-orion-platform/m/scripts/4223
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
      Throw 'Please install the SolarWinds PowerShell module first before running this script. It can be done in an elevated PowerShell console with: Install-Module -Name "SwisPowerShell"'
  }

  #Orion deployment connection Variables
  $OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
  $OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password: "

  #Build SW Information Service connection
  $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

  #Query Orion Nodes table
  $query = @"
      SELECT
        n.Caption AS [NodeName]
        ,n.NodeID AS [NodeID]
        ,n.Agent.AgentId AS [AgentID]
        ,n.Uri AS [URI]
        ,n.Engine.ServerName AS [EngineName]
        ,n.Engine.EngineID AS [EngineID]
      FROM Orion.Nodes n
      WHERE NodeID = 12
"@
  #Call into Orion API
  $QueryData = Get-SwisData -SwisConnection $swis -Query $query

  $NewEngineID = 4 #EngineID where agent node will be assigned

  #loop through all results returned by the query
  Foreach ($node in $QueryData) {
    $VerbArguments = @(
      $node.AgentID,
      $NewEngineID
    )  
      Write-Output "Updating $($node.NodeName) to polling engine: $($node.EngineName)"
      
      #This next line is intentionally left commented out. Uncomment the line to actually process the results.
      #Invoke-SwisVerb -SwisConnection $swis -EntityName "Orion.AgentManagement.Agent" -Verb "AssignToEngine" -Arguments $VerbArguments | Out-Null
  }
}
catch {
  $Errormsg = $_.Exception.Message
  Write-Output "ERROR: $Errormsg"
}
