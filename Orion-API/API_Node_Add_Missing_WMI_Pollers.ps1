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
    #$OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
    #$OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password: "
    #$NodeID = Read-Host "What is the NodeID of the node that you would like reset ICMP Pollers? "

    #Build SW Information Service connection
    $swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

    #Get Primary Orion Server Engine Info
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
            AND n.MachineType NOT LIKE '%2003%'
            AND n.MachineType NOT LIKE '%2008%'
"@

    #Call into the Orion API to get data
    $NodeResetList = Get-SwisData -SwisConnection $swis -Query $swql

    #Check that query returned data
    if ($null -eq $NodeResetList -OR $NodeResetList -eq "") {
        Throw "INFO: Unable to find any nodes with that match the query..."
    }

    #Add all entries for Poller
    foreach ($node in $NodeResetList){ 
        $poller = @{
            NetObject     = "N:" + $node.NodeID;
            NetObjectType = "N";
            NetObjectID   = $node.NodeID;
        }

        if ($node.CPUPollerType -ne "N.Cpu.WMI.WindowsPct") {
            $poller["PollerType"] = "N.Cpu.WMI.WindowsPct";

            Write-Output "Adding WMI CPU poller to $($node.Caption)"
            New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller | Out-Null
        }
        if ($node.MemPollerType -ne "N.Memory.WMI.Windows") {
            $poller["PollerType"] = "N.Memory.WMI.Windows";

            Write-Output "Adding WMI Memory poller to $($node.Caption)"
            New-SwisObject $swis -EntityType "Orion.Pollers" -Properties $poller | Out-Null
        }
    }
    
    Write-Output "Finished..."
}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "$Errormsg" 
}