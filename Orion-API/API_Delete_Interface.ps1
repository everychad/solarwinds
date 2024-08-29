<#
.SYNOPSIS
  This script will do a thing.
.DESCRIPTION
  This provides more details of the thing.
.PARAMETER None
  <none>
.INPUTS
  <Inputs if any, otherwise state None>
.OUTPUTS
  Writes to console the status of what is being processed.
.NOTES
  Version:        1.0
  Author:         Chad Every
  Creation Date:  2020/MAR/24
  Purpose/Change: Initial script development
  Website:        
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

# query to get node name, interface name, and interface URI of each non-up
# interface
$query = "
    SELECT
        Interfaces.Node.Caption AS NodeName
        ,Interfaces.Caption AS InterfaceName
        ,Interfaces.URI
        ,Interfaces.Status
    FROM Orion.NPM.Interfaces AS Interfaces
    WHERE Interfaces.InterfaceID = 8
"

$results = Get-SwisData $swis $query

foreach ($result in $results) {
    Write-Host ("Deleting interface [{0}] from node [{1}] with status [{2}]" -f $result.InterfaceName, $result.NodeName, $result.Status)

    # un-comment this line to do the actual deletion
    #Remove-SwisObject $swis $result.URI
}

