Function Compare-WSUSAD {
    <#
    .SYNOPSIS
        Compares Active Directory and WSUS to check workstations that are present on one and not on the other.

    .DESCRIPTION
        Compares Active Directory and WSUS to check workstations that are present on one and not on the other.

    .NOTES
        Name: Compare-WSUSAD
        Author: Marcelo Sizer
        Version History:
            1.0 | 30 Apr 2019
                -Initial Version

    .EXAMPLE
    Compare-WSUSAD

    Description
    This command generates the list of computers present only on AD or WSUS.
    #>

    $result = @()
	$searchBase = <## Set AD searchBase ##>
	$server = <## Set Domain Controller ##>

    # Gathers workstations FQDN from AD
    $compAD = Get-ADComputer -SearchBase $searchBase -Filter '*' -Server $server -Properties DNSHostName,IPv4Address,LastLogonDate,OperatingSystem,OperatingSystemVersion | Select-Object DNSHostName,IPv4Address,LastLogonDate,OperatingSystem,OperatingSystemVersion
    # Gathers workstations FQDN from WSUS
    $compWsus = Get-PSWSUSClient -IncludeDownstreamComputerTargets | Where-Object {$_.FullDomainName -notlike "*.tre*"} | Select-Object FullDomainName,IPAddress,LastReportedStatusTime,OSDescription,ClientVersion

	# Tests if workstations are responding and creates properties
    $result = Compare-Object $compAD.DNSHostName $compWsus.FullDomainName | ForEach-Object {
        Test-Connection -ComputerName $_.InputObject -Count 1 -AsJob
    } | Get-Job | Receive-Job -Wait | Select-Object @{Name='FQDN';Expression={$_.Address}},
                                                    @{Name='IP';Expression={''}},
                                                    @{Name='LastContact';Expression={''}},
                                                    @{Name='OS';Expression={''}},
                                                    @{Name='OSVersion';Expression={''}},
                                                    @{Name='Compare';Expression={''}},
                                                    @{Name='Ping';Expression={if ($_.StatusCode -eq 0) { $true } else { $false }}},
                                                    @{Name='Message';Expression={''}}

    # Edits values
    foreach ($computer in $compAD) {
        $result.GetEnumerator() | Where-Object {$_.FQDN -eq $computer.DNSHostName} | Where-Object {$_.IP = $computer.IPv4Address;
                                                                                                   $_.LastContact = $computer.LastLogonDate;
                                                                                                   $_.OS = $computer.OperatingSystem;
                                                                                                   $_.OSVersion = $computer.OperatingSystemVersion;
                                                                                                   $_.Compare = 'AD'}
    }
    foreach ($computer in $compWsus) {
        $result.GetEnumerator() | Where-Object {$_.FQDN -eq $computer.FullDomainName} | Where-Object {$_.IP = $computer.IPAddress;
                                                                                                      $_.LastContact = $computer.LastReportedStatusTime;
                                                                                                      $_.OS = $computer.OSDescription;
                                                                                                      $_.OSVersion = $computer.ClientVersion;
                                                                                                      $_.Compare = 'WSUS'}
    }

    $result = $result | Sort-Object compare,lastcontact
    return $result
}