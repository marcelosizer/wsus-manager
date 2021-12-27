[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-Module -Name PSScriptAnalyzer -Force

describe 'Module-level tests' {

    it 'the module imports successfully' {
        { Import-Module -Name "$PSScriptRoot\wsus-manager.psm1" -ErrorAction Stop } | should -not -throw
    }

    it 'the module has an associated manifest' {
        Test-Path "$PSScriptRoot\wsus-manager.psd1" | should -Be $true
    }

    it 'passes all default PSScriptAnalyzer rules' {
        Invoke-ScriptAnalyzer -Path "$PSScriptRoot\wsus-manager.psm1" | should -BeNullOrEmpty
    }

}