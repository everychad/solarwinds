<#
.SYNOPSIS
  This script is used for SolarWinds HA Failover.
.DESCRIPTION
  We have a unique scenario that we had to account for on our SolarWinds HA setup. This simple script allows for a PowerShell 
  script to be run to force a HA failover.
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
  Website:        https://thwack.solarwinds.com/content-exchange/the-orion-platform/m/scripts/3767
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
param (
    [Parameter()]
    [int]
    $HAPoolId
)

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

Write-Output "Forcing HA failover on HA Pool ID: $HAPoolId"
Invoke-SwisVerb -SwisConnection $swis -EntityName "Orion.HA.Pools" -Verb "Switchover" -Arguments $HAPoolId | Out-Null

exit 0
