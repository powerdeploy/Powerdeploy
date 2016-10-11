$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Resolve-Path $here\..\_build\Powerdeploy.psd1

. $here\..\Source\Functions\New-DeploymentPackage.ps1

if (-not ((Get-Module Powerdeploy) -eq $null)) {
    Remove-Module Powerdeploy
}

Import-Module $modulePath

Describe 'Install-DeploymentPackage, given a test package "TestPackage1"' {

    Setup -Dir package
    Setup -Dir temp

    $testFolder = Get-PSDrive TestDrive | Select -Expand Root
    $packageFolder = Join-Path $testFolder 'package'
    $tempFolder = Join-Path $testFolder 'temp'
    $extractedFolder = Join-Path $testFolder 'extracted'
    $packageLog = Join-Path $extractedFolder 'install.log'

    $package = New-DeploymentPackage `
        -SourcePath $here\TestPackage1 `
        -PackageName SuperApp `
        -Version 1.2.3 `
        -OutputDirectoryPath $packageFolder

    Install-DeploymentPackage `
        -PackageArchive $package.FullName `
        -Environment 'acceptance' `
        -Variable @{ 
            'url' = 'http://suspendedgravity.com'; 
            'connection' = 'mssql://mydatabase';
            'UTF8Setting' = 'テスト'
            } `
        -PackageTargetPath $extractedFolder 

    # Debugging
    Get-Content $packageLog -Encoding UTF8 | Write-Host

    # It 'executes pre-install scripts' {

    #     Get-Content $packageLog | Write-Host
    #     Get-Content $packageLog | Select-String 'deploy script executed' | should not be $null
    # }

    It 'executes init script' {
        $packageLog | should contain 'init script executed'
    }

    It 'provides the extracted package path through Get-DeploymentFolder' {
        $packageLog | should contain ([Regex]::Escape("init: Get-DeploymentFolder: $extractedFolder"))
    }

    It 'provides deployment variables through Get-DeploymentVariable' {
        $packageLog | should contain 'init: Get-DeploymentVariable url: http://suspendedgravity.com'
        $packageLog | should contain 'init: Get-DeploymentVariable connection: mssql://mydatabase'
        $packageLog | should contain 'init: Get-DeploymentVariable UTF8Setting: テスト'
    }
    # It 'executes install script' {

    #     Get-Content $packageLog | Select-String 'install script executed' | should not be $null
    # }

    # It 'executes deployment scripts in the correct order' {
        
    # }
}


Remove-Module Powerdeploy