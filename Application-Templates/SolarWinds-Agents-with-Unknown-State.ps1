<#
.SYNOPSIS
  This script will check the status of all agents in the SolarWinds Platform and count how many are in an Unknown state.
.DESCRIPTION
  We needed to monitor and alert against the count of agent status, specifically a status of unknown. This script calls into
  the SolarWinds Platform API via SWIS and queries for the information.
.PARAMETER None
  <none>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2023/MAY/23
  Purpose/Change: Initial script development
  Website:        https://thwack.solarwinds.com/content-exchange/server-application-monitor/m/application-monitor-templates/3766
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

#Verify that SolarWinds SWIS Module is imported
function GetModule {
    param (
        [string] $ModuleName
    )
    Try {
        Import-Module -Name $ModuleName
        } 
        catch {
            Write-Output "Unable to load $ModuleName Module, trying the PSSnapin..."  
            try {
            Add-PSSnapin -Name $ModuleName -ErrorAction Stop
            }
                catch {
                Write-Output "$ModuleName Module is NOT INSTALLED on this machine !"
                return
                }
        }
}

#---------------------------------------------------------------------------
#Start of script

#Import Powershell Modules
GetModule "SwisPowershell"

#SolarWinds deployment connection Variables
$SolarWindsMainServer = 'localhost'

#Build SW Information Service connection
$swis = Connect-Swis -Hostname $SolarWindsMainServer -Certificate

#Query Orion Nodes table
$NodeData = Get-SwisData `
    -SwisConnection $swis `
    -Query "SELECT 
              Agent.Engine.DisplayName
            ,UnknownAgents.UnknownAgents
            ,COUNT(Agent.AgentId) AS [TotalAgentsPerEngine]
            ,ROUND((((UnknownAgents.UnknownAgents +0.00) / (COUNT(Agent.AgentId)))*100),2) AS PercentageOfUnknownAgents
            FROM Orion.AgentManagement.Agent Agent
            JOIN (SELECT PollingEngineId
                ,COUNT(AgentStatusMessage) AS UnknownAgents
                FROM Orion.AgentManagement.Agent
                WHERE AgentStatusMessage = 'Unknown' 
                GROUP BY PollingEngineId) UnknownAgents ON UnknownAgents.PollingEngineId = Agent.PollingEngineId
            GROUP BY Agent.Engine.DisplayName, UnknownAgents.UnknownAgents
            ORDER BY PercentageOfUnknownAgents DESC
            "

$AgentsInUnknownState = New-Object -TypeName "System.Collections.ArrayList"
$AgentsInUnknownStateMessage = New-Object -TypeName "System.Collections.ArrayList"

foreach ($entry in $NodeData) {
  $AgentsInUnknownState.Add($entry.UnknownAgents) | Out-Null
  $AgentsInUnknownStateMessage.Add("$($entry.DisplayName): $($entry.PercentageOfUnknownAgents)%") | Out-Null
}

Write-Output "Statistic.AgentsInUnknownState: $(($AgentsInUnknownState | Measure-Object -Sum).Sum)"
Write-Output "Message.AgentsInUnknownState: Engines with agents in unknown state by percentage: $($AgentsInUnknownStateMessage -Join ', ')"

exit 0
