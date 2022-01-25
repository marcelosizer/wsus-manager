function Remove-WSUSComputer {
    <#
    .SYNOPSIS
        Removes computers that don't exist from WSUS.

    .DESCRIPTION
        Removes computers that don't exist from WSUS.

    .PARAMETER Scope
        Mandatory parameter. Defines the scope of the WSUS Server.

    .NOTES
        Name: Remove-WSUSComputer
        Author: Marcelo Sizer
        Version History:
            1.0 | 12 Mar 2019
                -Initial Version
            2.0 | 27 Apr 2019

    .EXAMPLE
    Remove-WSUSComputer -Scope "Server"

    Description
    -----------
    This command applies the computer removal rules to the WSUS Server.
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [ValidateSet('Server','Workstation')]
        [string]$Scope
    )

    # Defines $WsusServer
    $WsusServer = (Get-PSWSUSServer).Name

    # Loads variables
	$pathHome = # Define path to store variables loaded by the script
	$pathLogs = # Define log path
	$fileServer = # Path to file server
    $DateLog = Get-Date -Format o
    $DateLog = $DateLog.SubString(0,10)
    $dupeDownstreamName = @()
    $dupeName = @()
	$wsusDownstreamServer = <# Add WSUS server FQDN#>
	$srvDownstream1 = @()

    if ($Scope -eq "Server") {
        # Imports exclusion list
        $excludeList = Get-Content "$pathHome\ExcludeList$Scope.txt"
        # Adds to the variable $compWSUS if server is not on exclusion list and $_.compare is equal to 'WSUS'
        $compWSUS = Compare-WSUSCMDB
        $compWSUS = $compWSUS | ForEach-Object {if ($_.compare -eq 'WSUS' -and $_.fqdn -notin $excludeList) {$_}}
        $serverInfo = Get-PSWSUSClient -IncludeDownstreamComputerTargets
        # Checks if there are computers to be removed from downstream servers
        foreach ($srv in $compWsus) {
            $serverInfo.GetEnumerator() |
                Where-Object {$_.FullDomainName -eq $srv.fqdn} |
                Where-Object {$srv.server = $_.ParentServerId}
            if ($srv.server -eq <# Add WSUS server GUID #>) {
                $srv.server = $wsusDownstreamServer
                $srvDownstream1 += $srv
            } else {$srv.server = $wsusServer}
        }
    } elseif ($Scope -eq "Workstation") {
        # Adds to the variable $compWSUS if server is $_.compare is equal to 'WSUS', is not responding and hasn't communicated with Active Directory for over 365 days
        $compWSUS = Compare-PRWSUSAD
        $compWSUS = $compWSUS | ForEach-Object {if ($_.compare -eq 'WSUS' -and $_.ping -eq $false -and $_.LastContact -le (Get-Date).AddDays(-365)) {$_}}
    }

    $numCompWSUS = ($compWSUS | Measure-Object).count
    # Removes computer objects from Downstream WSUS computers
    if ($numCompWSUS -gt 0) {
        if (($srvDownstream1 | Measure-Object).Count -gt 1) {
            $dupeDownstreamName = Invoke-Command -Computername $wsusDownstreamServer -ScriptBlock {
                Import-Module PoshWsus
                Connect-PSWSUSServer -WsusServer $wsusDownstreamServer -Port 8531 -SecureConnection | Out-Null
                $Using:srvDownstream1 | Foreach-Object {
                    $compName = $_.fqdn
                    $singleClient = Get-PSWSUSClient -ComputerName $compName
                    if (($singleClient | Measure-Object).Count -gt 1) {
                        $dupeDownstreamName += $compName
                    } else {
                        Remove-PSWSUSClient -Computername $compName
                    }
                }
                return $dupeDownstreamName
            }
        }
        $dupeName += $dupeDownstreamName
        $dupeName | Foreach-Object {
			$errorMessage = "Cannot remove the name '$_' because it returns more than one computer object in WSUS. Please delete this computer manually."
		    $errorMessage | Out-File "$PathLogs\$DateLog-ComputersRemoved-$WsusServer.log" -Append
            $compWSUS | Where-Object {$_.fqdn -eq $dupeName} | Where-Object {$_.Message = $errorMessage}
        }

        # Removes computers in $compWSUS variable from WSUS upstream server
        $compWSUS | Foreach-Object {
            $compName = $_.fqdn
            # Ensures only 1 computer is returned.
            $singleClient = Get-PSWSUSClient -NameIncludes $compName -IncludeDownstreamComputerTargets
            if (($singleClient | Measure-Object).Count -gt 1) {
                $dupeUpstreamName = $compName
                $errorMessage = "Cannot remove the name '$dupeUpstreamName' because it returns more than one computer object in WSUS. Please delete this computer manually."
                $errorMessage | Out-File "$PathLogs\$DateLog-ComputersRemoved-$WsusServer.log" -Append
                $compWSUS | Where-Object {$_.fqdn -eq $dupeUpstreamName} | Where-Object {$_.Message = $errorMessage}
                $numCompWSUS -= 1
            } else {
                # Needs edited version of Remove-PSWSUSClient from PoshWSUS; PR available on GitHub repo.
				$singleClient | Remove-PSWSUSClient
                $_ | Out-File "$PathLogs\$DateLog-ComputersRemoved-$WsusServer.log" -Append
            }
        }
        $hashFunction.AllFunctions += @{
            'Name'= 'ComputersRemoved';
            'Description' = "$numCompWSUS computers removed from $scope`s WSUS.";
            'Value' = $compWSUS
        }
        return $hashFunction.AllFunctions
    } else {"No computers removed." | Out-File "$PathLogs\$DateLog-ComputersRemoved-$WsusServer.log"}
}