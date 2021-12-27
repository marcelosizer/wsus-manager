@{
    RootModule = 'C:\Program Files\WindowsPowerShell\Modules\wsus-manager\wsus-manager.psm1'
    ModuleVersion = '1.0'
    GUID = 'c1b2ac54-27b7-4c07-894b-163478ceea14'
    Author = 'Marcelo Sizer'
    Description = 'Powershell Module to manage WSUS'
    PowerShellVersion = '5.1'
    RequiredModules = @('PoshWSUS')
    FunctionsToExport = @('Compare-WSUSAD','Compare-WSUSCMDB','Get-WSUSClientPendingUpdate','Get-WSUSInfo','Get-WSUSLastReport','Invoke-WSUSMaintenance','Remove-WSUSComputer','Remove-WSUSUpdate','Set-WSUSUpdateApproval','Send-WSUSEmail')
}
