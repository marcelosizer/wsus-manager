function Invoke-WSUSMaintenance {
    <#
    .SYNOPSIS
        Manages WSUS servers.

    .DESCRIPTION
        Manages WSUS servers.

    .PARAMETER Workstation
        Invokes maintenance procedures in the workstations WSUS server.

    .PARAMETER Server
		Invokes maintenance procedures in the servers WSUS server.
    .NOTES
        Name: Invoke-WSUSMaintenance
        Author: Marcelo Sizer
        Version History:
            1.0 | 27 Apr 2019
                -Initial Version

    .EXAMPLE
    Invoke-WSUSMaintenance -Workstation

    Description
    -----------
    Invokes maintenance procedures in the workstation WSUS server.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'WSUSServers')]
        [switch]$Workstation,

        [Parameter(Mandatory = $true, ParameterSetName = 'WSUSEstacoes')]
        [switch]$Server
    )
    begin {
        $pathHome = <## Path to save logs and get input data ##>
        $hashFunction = @{
            AllFunctions = @(
                @{
                    'Name' = $null
                }
            )
        }
    }
    process {
        if ($Workstation) {
            $choice = 'Workstation'
            Connect-PSWSUSServer -WsusServer <## WSUS Server FQDN ##> -Port 8531 -SecureConnection | Out-Null
        } elseif ($Server) {
            $choice = 'Server'
            Connect-PSWSUSServer -WsusServer <## WSUS Server FQDN ##> -Port 8531 -SecureConnection | Out-Null
        }

        # Remove Computers WSUS
        $hashFunction.AllFunctions += Remove-WSUSComputer -Scope $choice

        # Set Update Approval WSUS
        $hashFunction.AllFunctions += Set-WSUSUpdateApproval

        # Remove Updates WSUS
        $hashFunction.AllFunctions += Remove-WSUSUpdate

        # Sends email report
        $recipients = Get-Content "$pathHome\Recipients$choice.txt"
        Send-WSUSEmail -Recipients $recipients -Email <## reply-email ##> -Subject "WSUS $choice`s Maintenance routines." -hashfunction $hashFunction
    }
}