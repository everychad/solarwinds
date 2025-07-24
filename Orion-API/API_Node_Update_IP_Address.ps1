<#
.SYNOPSIS
  This script will update a node with a new IP Address. Script will prompt for details.
.DESCRIPTION
  This script was built to test updating an IP Address for a node via the API.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2025/JUL/24
  Purpose/Change: Initial script development
  Website:        https://github.com/everychad/solarwinds/blob/master/Orion-API/API_Node_Update_FQDN_With_Hostname.ps1
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

#Orion deployment connection Variables
$OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
$OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password"
$NodeID = Read-Host "Enter the NodeID of the Node whose IP Address you want to change: "
$NewIPAddress = Read-Host "Enter the new IP Address for your node: "

#Build SW Information Service connection
$swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

#Query Orion Nodes table.  This query can be expanded if you need to narrow down the resutls.
$NodeData = Get-SwisData `
    -SwisConnection $swis `
    -Query "SELECT Caption, IP_Address, Uri
            FROM Orion.Nodes
            WHERE NodeID = $NodeID"

Write-Output "Pre-API Call to update IP Address for $($NodeData.Caption). Current IP Address: $($NodeData.IP_Address)`n"
Write-Output "Calling API to update Node IP Address`n"
Set-SwisObject $swis -Uri $NodeData.Uri -Properties @{IP_Address = $NewIPAddress}

#Call into API to fetch changes
$NodeData = Get-SwisData `
    -SwisConnection $swis `
    -Query "SELECT Caption, IP_Address, Uri
            FROM Orion.Nodes
            WHERE NodeID = $NodeID"

Write-Output "Post-API Call to update IP Address for $($NodeData.Caption). New IP Address: $($NodeData.IP_Address)"