<#
.SYNOPSIS
  This script will update a node with a FQDN to only its hostname.
.DESCRIPTION
  There are times where nodes will be onboraded with their hostname and other times they might be onboarded with their FQDN. 
  This script will strip out the domain name from the FQDN and then update the node Caption with only the hostname.
.PARAMETER None
  <none>
.INPUTS
  <None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2024/APR/26
  Purpose/Change: Initial script development
  Website:        https://github.com/everychad/solarwinds/blob/master/Orion%20API/API_Node_Update_FQDN_With_Hostname.ps1
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

#Build SW Information Service connection
$swis = Connect-Swis -Credential $OrionCreds -Hostname $OrionHostname

#Query Orion Nodes table.  This query can be expanded if you need to narrow down the resutls.
$NodeData = Get-SwisData `
    -SwisConnection $swis `
    -Query "SELECT Caption, Uri
            FROM Orion.Nodes
            WHERE Vendor = 'Windows'"

#Loop through each entry from the query above and update the Node Caption, if applicable.
Foreach ($node in $NodeData) {
  If ( $node.Caption -like "*.*" ) {
    Write-Output "Node: $($node.Caption) removing FQDN, updating to $($node.Caption.Split('.')[0])..."
    
    #Set-SwisObject $swis -Uri $($node.Uri) -Properties @{Caption = $($node.Caption.Split(".")[0])}
  }
  Else {
     Write-Output "Node: $($node.Caption) skipping..."
  }
}