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
  Creation Date:  2024/APR/26
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