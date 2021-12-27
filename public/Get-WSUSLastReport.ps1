Function Get-WSUSLastReport {
    <#
    .SYNOPSIS
        Gathers information from servers and workstations that are not reporting to WSUS for over N days.
		
    .DESCRIPTION
        Gathers information from servers and workstations that are not reporting to WSUS for over N days.
        By default, servers and workstations that don't report for over 30 days.

    .PARAMETER Date
		Date to recover servers that aren't reporting to WSUS. Default value = 30 days.

    .EXAMPLE
        Get-WSUSLastReport

        Description
        -----------
        Coleta os computadores que não reportam ao servidor de WSUS há mais de 30 dias.

    .EXAMPLE
        Get-WSUSLastReport -Date 90

        Description
        -----------
        Gathers information from servers that are not reporting to WSUS for over 90 days.

    .NOTES
        Name: Get-WSUSLastReport
        Authors: André Luis Ribeiro Gonçalves and Marcelo Sizer
        Version History:
            1.0 | 28 Nov 2018
                Andre Luis Ribeiro Goncalves
                -Initial Version
            2.0 | 30 Apr 2019
                Marcelo Sizer
    #>

    [CmdletBinding()]
    Param (
        [datetime]$Date = (Get-Date).AddDays(-30)
    )
    $result = @()

    # Gathers computers that aren't reporting to WSUS
    $compLastReport = Get-PSWSUSClient -IncludeDownstreamComputerTargets -ToLastStatusTime $date
    $result = Get-PSWSUSClient -IncludeDownstreamComputerTargets -ToLastStatusTime $date | ForEach-Object {
        Test-Connection -ComputerName $_.FullDomainName -Count 1 -AsJob
    } | Get-Job | Receive-Job -Wait | Select-Object @{Name='ComputerName';Expression={$_.Address}},@{Name='LastReport';Expression={$date}},@{Name='Ping';Expression={if ($_.StatusCode -eq 0) { $true } else { $false }}}
    # Edits the LastReport field with the correct date
    foreach ($computer in $compLastReport) {
        $result.GetEnumerator() | Where-Object {$_.computername -eq $computer.FullDomainName} | Where-Object {$_.lastreport = $computer.LastReportedStatusTime}
    }
    $result = $result | Sort-Object Ping -Descending
    return $result
}