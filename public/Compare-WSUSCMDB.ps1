Function Compare-WSUSCMDB {
    <#
    .SYNOPSIS
		Compares a CMDB and WSUS to check servers that are present on one and not on the other.

    .DESCRIPTION
		Compares a CMDB and WSUS to check servers that are present on one and not on the other.

    .NOTES
        Name: Compare-WSUSCMDB
        Authors: André Luis Ribeiro Gonçalves and Marcelo Sizer
        Version History:
            1.0 | 23 Nov 2018
                -Initial Version
                André Luis Ribeiro Gonçalves
            2.0 | 30 Apr 2019
                Marcelo Sizer

    .EXAMPLE
    Compare-WSUSCMDB

    Description
    -----------
    This command generates the list of computers present only on the CMDB or WSUS.
    #>

    $result = @()

    # Gathers server information from the CMDB
    $CMDBInfo = <## Get FQDN information from CMDB ##>

	# Gathers server information from WSUS
	$wsusInfo = Get-PSWSUSClient -IncludeDownstreamComputerTargets | Foreach-Object {$_.FullDomainName.ToLower() }

    $compare = Compare-Object $CMDBInfo $wsusInfo

    ($compare | Where-Object SideIndicator -eq '<=').InputObject | ForEach-Object {$_.split('.')[0]} | <## Fills computer information from CMDB ##> | Foreach-Object {
        $i = '' | Select-Object fqdn,compare,server,message
        $i.fqdn = $_.fqdn
        $i.compare = 'CMDB'
        $i.server = '-'
        $i.message = ''
        $result += $i
    }
    ($compare | Where-Object SideIndicator -eq '=>').InputObject | Foreach-Object {
        $i = '' | Select-Object fqdn,compare,server,message
        $i.fqdn = $_
        $i.compare = 'WSUS'
        $i.server = ''
        $i.message = ''
        $result += $i
    }
    return $result
}