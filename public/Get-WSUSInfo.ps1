function Get-WSUSInfo {
    <#
    .SYNOPSIS
        Collects information from WSUS Servers.

    .DESCRIPTION
        Collects information from WSUS Servers.

    .PARAMETER Workstation
        Collects data from the Workstations WSUS server.

    .PARAMETER Server
        Collects data from the Servers WSUS server
		
    .NOTES
        Name: Get-WSUSInfo
        Author: Marcelo Sizer
        Version History:
            1.0 | 26 Feb 2019
                -Initial Version

    .EXAMPLE
    Get-WSUSInfo -Workstation

    Description
    -----------
    This command will invoke all the information gathering functions from the module for the Workstations WSUS server.

    .EXAMPLE
    Get-WSUSInfo -Server

    Description
    -----------
    This command will invoke all the information gathering functions from the module for the Servers WSUS server.

    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'WSUSServers')]
        [switch]$Workstation,

        [Parameter(Mandatory = $true, ParameterSetName = 'WSUSWorkstations')]
        [switch]$Server
    )
    begin {
        # Loads variables
        $pathHome = # Define path to store variables loaded by the script
		    $fileServer = # Path to file server
        $PUServers = @()
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
            Connect-PSWSUSServer -WsusServer <## WSUS Server FQDN ##> -Port 8531 -SecureConnection | Out-Null
            $choice = 'Workstation'
            # Checks for workstations that don't exist on Active Directory and removes them from WSUS
			      $ADxWSUS = Compare-WSUSAD
        } elseif ($Server) {
            Connect-PSWSUSServer -WsusServer <## WSUS Server FQDN ##> -Port 8531 -SecureConnection | Out-Null
            $choice = 'Server'
            # Compares servers that exist on CMDB and don't exist on WSUS and vice-versa
            $CMDBxWSUS = Compare-WSUSCMDB
        }

        # Pending Updates WSUS
        $PendingUpdates = Get-WSUSClientPendingUpdate
        $PendingUpdates = $PendingUpdates | Where-Object Computer -ne $null | Select-Object Computer,Needed,Failed,NotInstalled,PendingReboot
        $PendingUpdates | Select-Object -Property @{Name='Computer';Expression={$_.computer.split('.')[0]}} | Export-Csv -Path "$fileServer\Pending$choice`s.csv" -NoTypeInformation

        # Last Report WSUS
        $LastReport = Get-WSUSLastReport
        $LastReport = $LastReport | Where-Object ComputerName -ne $null
        $LastReport | Select-Object -Property @{Name='ComputerName';Expression={$_.ComputerName.split('.')[0]}} | Export-Csv -Path "$fileServer\Last$choice`s.csv" -NoTypeInformation

        # CMDB x WSUS
        $numCMDBxWSUS = $CMDBxWSUS.count
        if ($numCMDBxWSUS -gt 0) {
            $hashFunction.AllFunctions += @{
                'Name'= 'CMDBxWSUS';
                'Description' = "$numCMDBxWSUS server(s) identified";
                'Value' = $CMDBxWSUS
            }
        }

        # AD x WSUS
        $numADxWSUS = $ADxWSUS.count
        if ($numADxWSUS -gt 0) {
            $hashFunction.AllFunctions += @{
                'Name'= 'ADxWSUS';
                'Description' = "$numADxWSUS server(s) identified";
                'Value' = $ADxWSUS
            }
        }

        # Pending Updates WSUS
        $numPendingUpdates = ($PendingUpdates | Measure-Object).count
        if ($numPendingUpdates -gt 0) {
            $hashFunction.AllFunctions += @{
                'Name'= 'PendingUpdates';
                'Description' = "$numPendingUpdates computers have pending updates which are over 90 days old";
                'Value' = $PendingUpdates
            }
        }

        # Last Report WSUS
        $numLastReport = ($LastReport | Measure-Object).count
        if ($numLastReport -gt 0) {
            $hashFunction.AllFunctions += @{
                'Name'= 'LastReport';
                'Description' = "$numLastReport computers haven't reported in over 30 days";
                'Value' = $LastReport
            }
        }

        # E-mail report
        $recipients = Get-Content "$pathHome\Recipients$choice.txt"
        Send-WSUSEmail -Recipients $recipients -Email <## reply-email ##> -Subject "WSUS $choice`s information gathering routines." -hashfunction $hashFunction
    }
}
