<#
.SYNOPSIS
  This script will update a Node Custom Property without using any the SolarWinds SWISPowerShell module.
.DESCRIPTION
  While I find using the SolarWinds SWISPowerShell module easier, i needed an example of using raw JSON. This example is 
  merely for reference. In a real-life scenario this script would be modified to loop through an array of nodeIDs for 
  faster usage.
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

#Ignore self-signed certificate warnings
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    #Orion deployment connection Variables
    $OrionHostname = Read-Host "Enter your Orion Hostname or IP Address: "
    $OrionCreds = Get-Credential -Message "Please enter your Orion Web Console Username and Password: "
    $NodeID = Read-Host "What is the Node ID for the node that you would like to update?"
    $CustomPropertyName = Read-Host "What is the name of the Custom Property that you would like to update?"
    $CustomPropertyValue = Read-Host "What is the new value of this Custom Property?"

    #Craft necessary URL/URI for Node Custom Property
    $swisuri = "swis://$OrionHostname/Orion/Orion.Nodes/NodeID=$NodeID/CustomProperties"
    $url = "https://$OrionHostname`:17778/SolarWinds/InformationService/v3/Json/$swisuri"

    #Format Custom Property name/value into JSON. e.g. { "name":  "value" }
    $json = @{ $CustomPropertyName = $CustomPropertyValue } | ConvertTo-Json

    #API Call into Orion the make the request
    $Result = Invoke-WebRequest -Uri $url -Credential $OrionCreds -Method Post -Body $json -ContentType application/json

    if ($Result.StatusCode -eq 200 ) {
        Write-Output "Updated Custom Property $CustomPropertyName to $CustomPropertyValue on Node ID $NodeID"
    }
}
catch {
    $Errormsg = $_.Exception.Message
    Write-Output "ERROR: $Errormsg"
}
