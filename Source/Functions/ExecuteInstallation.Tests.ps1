$global:TestContext = @{}
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$installerModulePath = "$here\..\Helpers\Functions\DeploymentContext.ps1"
. $here\..\MimicModule.Tests.ps1
. $here\..\TestHelpers.ps1
# . $installerModulePath
. $here\..\Helpers\Common.Tests.ps1

Describe 'ExecuteInstallation' {

    # Mock RunConventions { $global:TestContext.conventionsHadContext = $global:TestContext.contextCalled }
    Mock Set-DeploymentContext { $global:TestContext.contextCalled = $true }
    Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
    Mock GetInstallationExtensionRoot { resolve-path testdrive:\ }
    #Mock Import-Module { } -ParameterFilter { $Name -like '*Installer.psm1' }

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -Settings @{ 'somesetting' = 'somevalue' }

    It 'configures the deployment context' {
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $EnvironmentName -eq 'prod-like' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $DeployedFolderPath -eq 'testdrive:\package-target' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageName -eq 'fuzzy-bunny' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageVersion -eq '9.3.1' }
    }

    It 'configures the deployment context settings' {
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { (&{$Variables}).somesetting -eq 'somevalue' }
    }
}

Describe 'ExecuteInstallation, with extensions' {
    Setup -Dir extensions\extension1
    Setup -File extensions\extension1\initialize.ps1 @'
        Set-Content testdrive:\called.txt ""
        Register-DeploymentScript -Pre -Phase Install -Script { }
        $context = Get-DeploymentContext
        Set-Content testdrive:\parms.txt "$($context.Parameters.PackageVersion)"
'@

    Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
    Mock Register-DeploymentScript { }
    Mock GetInstallationExtensionRoot { resolve-path testdrive:\extensions }
    Mock Remove-Module { }
    # Mock RunConventions { }

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -Settings @{ 'somesetting' = 'somevalue' }

    It 'initializes the extensions' {
        'testdrive:\called.txt' | should exist
    }

    It 'makes the deployment context available to the extensions' {
        'testdrive:\parms.txt' | should exist
    }

    It 'makes the helper cmdlets available to the extensions' {
        Assert-MockCalled Register-DeploymentScript
    }
}

Describe 'ExecuteInstallation, with an extension that fails to initialize' {

    $exception = Capture {
        Setup -Dir extensions\extension1
        Setup -File extensions\extension1\initialize.ps1 @'
    throw "badness"
'@

        Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
        Mock Register-DeploymentScript { }
        Mock GetInstallationExtensionRoot { resolve-path testdrive:\extensions }
        Mock Remove-Module { }
        Mock RunConventions { }

        ExecuteInstallation `
            -PackageName 'fuzzy-bunny' `
            -PackageVersion '9.3.1' `
            -EnvironmentName 'prod-like' `
            -DeployedFolderPath 'testdrive:\package-target' `
            -Settings @{ 'somesetting' = 'somevalue' }
    }

    It 'fails the installation' {
        $exception | should not be $null
    }
}

Describe 'ExecuteInstallation, with registered scripts for every phase' {
    Setup -Dir extensions

    $resultFile = 'testdrive:\result.txt'

    Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
    Mock GetInstallationExtensionRoot { resolve-path testdrive:\extensions }
    Mock Remove-Module { }

    # We'll initialize them in reverse to ensure that order of initialization
    # doesn't determine order of execution.
    Register-DeploymentScript -Post -Phase Configure -Script { 'post-configure' >> $resultFile }
    Register-DeploymentScript       -Phase Configure -Script { 'configure' >> $resultFile }
    Register-DeploymentScript -Pre  -Phase Configure -Script { 'pre-configure' >> $resultFile }
    Register-DeploymentScript -Post -Phase Install   -Script { 'post-install' >> $resultFile }
    Register-DeploymentScript       -Phase Install   -Script { 'install' >> $resultFile }
    Register-DeploymentScript -Pre  -Phase Install   -Script { 'pre-install' >> $resultFile }
    Register-DeploymentScript -Post -Phase Prepare   -Script { 'post-prepare' >> $resultFile }
    Register-DeploymentScript       -Phase Prepare   -Script { 'prepare' >> $resultFile }
    Register-DeploymentScript -Pre  -Phase Prepare   -Script { 'pre-prepare' >> $resultFile }

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -Settings @{ 'somesetting' = 'somevalue' }

    It 'executes all scripts in correct order' {
      $lines = Get-Content $resultFile
      $lines[0] | should be 'pre-prepare'
      $lines[1] | should be 'prepare'
      $lines[2] | should be 'post-prepare'
      $lines[3] | should be 'pre-install'
      $lines[4] | should be 'install'
      $lines[5] | should be 'post-install'
      $lines[6] | should be 'pre-configure'
      $lines[7] | should be 'configure'
      $lines[8] | should be 'post-configure'
    }
}

Describe 'ExecuteInstallation (as bdd)' {
    Mock Import-Module { } #-ParameterFilter { $Name -like '*Installer.psm1' }
    Mock Remove-Module { }

    $global:pester_pd_test_initialization_executed = $false
    $global:pester_pd_test_initialization_context_value = $null
    $global:pester_pd_test_preinstall_executed = $false
    $global:pester_pd_test_postinstall_executed = $false

    Setup -Dir 'package-target'
    Setup -Dir 'package-target\content'
    Setup -Dir 'package-target\deploy'

    Setup -File 'package-target\deploy\initialize.ps1' @'
$global:pester_pd_test_initialization_executed = $true

Register-DeploymentScript -Pre -Phase Install -Script { $global:pester_pd_test_preinstall_executed = $true; $global:pester_pd_test_initialization_context_value = Get-DeploymentPackageName }
Register-DeploymentScript -Post -Phase Install -Script { $global:pester_pd_test_postinstall_executed = $true }
'@

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -Settings @{ 'somesetting' = 'somevalue' }

    It 'executes the package initialization script' {
         $global:pester_pd_test_initialization_executed | should be $true
    }

    It 'executes pre-Install scripts' {
        $global:pester_pd_test_preinstall_executed | should be $true
    }

    It 'executes post-Install scripts' {
        $global:pester_pd_test_postinstall_executed | should be $true
    }

    It 'supplies the deployment context to the initialization script' {
        $global:pester_pd_test_initialization_context_value | should be 'fuzzy-bunny'
    }
}
