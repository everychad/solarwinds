<#
.SYNOPSIS
  This script will add missing pollers to a WMI node in Orion.
.DESCRIPTION
  This script will call into the Orion API and add missing WMI Pollers for Windows Servers. This can happen when the Windows 
  Server is originally polled via SNMP and is changed to WMI polling. A Network Discovery would still be needed to readd all
  of the network interfaces and volumes that need to be monitored.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2025/JAN/06
  Purpose/Change: Initial script development
  Website:        https://github.com/everychad/solarwinds/blob/master/Orion-API/API_Node_Add_Missing_WMI_Pollers.ps1
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
    $OrionHostname = Read-Host "Enter your SolarWinds Platform Hostname or IP Address: "
    $OrionCreds = Get-Credential -Message "Please enter your SolarWinds Platform Web Console Username and Password: "

    #Build SW Information Service connection
    $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

    #Get list of WMI nodes that do not have a CPU or Memory poller assigned to them. This excludes Windows Server 2003 and 2008
    $swql = @" 
        SELECT
        n.Caption
        ,n.IPAddress
        ,n.ObjectSubType
        ,CASE 
            WHEN cpu.PollerType IS NOT NULL THEN 'Assigned'
            ELSE 'Not Assigned'
            END AS [WMI CPU Poller]
        ,cpu.PollerType AS [CPUPollerType]
        ,CASE 
            WHEN mem.PollerType IS NOT NULL THEN 'Assigned'
            ELSE 'Not Assigned'
            END AS [WMI Memory Poller]
        ,mem.PollerType AS [MemPollerType]
        ,n.NodeID
        ,n.Uri
        FROM Orion.Nodes n
        LEFT JOIN (SELECT PollerID, PollerType, NetObjectID, Enabled FROM Orion.Pollers WHERE PollerType LIKE '%CPU%' AND PollerType LIKE '%WMI%') cpu ON cpu.NetObjectID = n.NodeID
        LEFT JOIN (SELECT PollerID, PollerType, NetObjectID, Enabled FROM Orion.Pollers WHERE PollerType LIKE '%mem%' AND PollerType LIKE '%WMI%') mem ON mem.NetObjectID = n.NodeID

        WHERE 1=1
            AND n.ObjectSubType IN ('WMI') 
            AND n.Vendor = 'Windows'
            AND (cpu.PollerType IS NULL OR mem.PollerType IS NULL)
"@

$XMLElementPoller = 'CPU & Memory'
$XMLLeefPoller = 'CPU & Memory by SolarWinds'

$ListOfNodes = Get-SwisData $swis $swql

foreach ($Node in $ListOfNodes)
{
  Write-Host "Node Name: $($Node.Caption), NodeID: $($Node.NodeID) - Enable CPU & Memory Polling"
  
  #Start List Resources job
  $JobID = Invoke-SwisVerb $swis Orion.Nodes ScheduleListResources $($Node.NodeID)
  
  #Check status of list resources job
  do
  {
      Start-Sleep -Seconds 5
      $JobStatus = Invoke-SwisVerb $swis Orion.Nodes GetScheduledListResourcesStatus @($JobID.'#text', $Node.NodeID)
      Write-Host "     Node Name: $($Node.Caption), NodeID: $($Node.NodeID) - JobID:" $JobID.'#text' "- Status:" $JobStatus.'#text'
  } while ($JobStatus.'#text' -ne "ReadyForImport")
  
  #Get results of list resouces job
  $JobResults = Invoke-SwisVerb $swis Orion.Nodes GetListResourcesResult @($JobID.'#text', $Node.NodeID)
  
  #Modify XML results to be selective on import
  $XMLElementBranch = $JobResults.DiscoveryResultExportItem.Children.DiscoveryResultExportItem | Where-Object {$_.DisplayName.'#text' -eq $XMLElementPoller} 
  $XMLElementBranch.IsSelected = 'true'
  $XMLElementBranch.DisplayName.'#text' = 'CPU &amp; Memory'
  $XMLLeefPollerID = $JobResults.DiscoveryResultExportItem.Children.DiscoveryResultExportItem.Children.DiscoveryResultExportItem.DisplayName | Where-Object '#text' -eq $XMLLeefPoller | Select-Object Id
  $XMLLeefPollerID = [int]$XMLLeefPollerID.Id - 1
  $XMLLeef = $JobResults.DiscoveryResultExportItem.Children.DiscoveryResultExportItem.Children.DiscoveryResultExportItem | Where-Object Id -EQ $XMLLeefPollerID 
  $XMLLeef.IsSelected = 'true'
  $XMLLeef.DisplayName.'#text' = 'CPU &amp; Memory by SolarWinds'
  
  #Import results
  $JobUpdate = Invoke-SwisVerb $swis Orion.Nodes ImportSelectedListResourcesResult @($JobID.'#text', $Node.NodeID, $JobResults)
  Write-Host "     Node Name: $($Node.Caption), NodeID: $($Node.NodeID) - JobID:" $JobID.'#text' " - Status:" $JobUpdate.Id "- Poller Import Completed"
  if ($JobUpdate.Id -eq 1) {
      Write-Host "     Node Name: $($Node.Caption) - Poller Import Completed"
  }
}

if ($null -eq $ListOfNodes) {
  Write-Host "Complete: No nodes found with missing CPU/Memory pollers"
}

}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "$Errormsg" 
}