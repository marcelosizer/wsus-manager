function Get-WSUSClientPendingUpdate {
    <#
    .SYNOPSIS
        List computers with pending updates older than 90 days.

    .DESCRIPTION
        List computers with pending updates older than 90 days.

    .PARAMETER Date
        Date to recover computers with pending updates in WSUS. Default value = 90 days.

    .NOTES
        Name: Get-WSUSClientPendingUpdate
        Author: Marcelo Sizer
        Version History:
            1.0 | 27 Nov 2018
                -Initial Version

    .EXAMPLE
    Get-WSUSClientPendingUpdate

    Description
    -----------
    This command will generate the list of updates from servers that have pending updates released over 90 days ago.

    .EXAMPLE
    Get-WSUSClientPendingUpdate -Date 30

    Description
    -----------
    This command will generate the list of updates from servers that have pending updates released over 30 days ago.
    #>

    [CmdletBinding()]
    Param (
        [datetime]$Date = (Get-Date).AddDays(-90)
    )

    $updateSum = @()
    $computers = @()

    # Lists updates approved over N days ago
    $updates = Get-PSWSUSUpdate -ApprovedState LatestRevisionApproved -ToArrivalDate $Date
    # Lists computers with pending updates
    $updates | ForEach-Object {
        $computers += Get-PSWSUSClientPerUpdate -Update $_ -ComputerScope (New-PSWSUSComputerScope -IncludedInstallationState Downloaded,Failed,InstalledPendingReboot,NotInstalled)
    }
    $computersUniq = $computers.computername | Sort-Object | get-unique
    # Generates a report with pending updates by computer
    $computersUniq | ForEach-Object {
        $updateSum += Get-PSWSUSUpdateSummaryPerClient -ComputerScope (New-PSWSUSComputerScope -NameIncludes $_)
    }
    return $updateSum
}