$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\TestHelpers.ps1
. $here\..\MimicModule.Tests.ps1

Describe 'Install-DeploymentPackage' {

    Setup -Dir pdtemp

    Mock ExtractPackage { }
    Mock ExecuteInstallation { }

    Install-DeploymentPackage `
        -PackageArchive 'somepackage_1.2.3.zip' `
        -Environment 'production' `
        -PackageTargetPath testdrive:\deploytome `
        -PostInstallScript { $PowerdeployDeploymentParameters | ConvertTo-Json | Out-File testdrive:\params.json } `
        -Variable @{ 'somesetting' = 'some-value' }

    It 'executes the installation' {
        Assert-MockCalled ExecuteInstallation -Exactly 1
    }

    It 'executes the installation with all of the deployment parameters' {
        Assert-MockCalled ExecuteInstallation -ParameterFilter { `
            $PackageName -eq 'somepackage' `
            -and $PackageVersion -eq '1.2.3' `
            -and $EnvironmentName -eq 'production' `
            -and $DeployedFolderPath -eq 'testdrive:\deploytome' `
        }
    }

    It 'executes post install script' {
        Test-Path testdrive:\params.json | should be $true
    }

    It 'makes deployment parameters available to post install script' {
        $params = Get-Content testdrive:\params.json -Raw -Encoding UTF8 | ConvertFrom-Json

        $params.PackageName | should be 'somepackage'
        $params.PackageVersion | should be '1.2.3'
        $params.EnvironmentName | should be 'production'
        $params.DeployedFolderPath | should be 'testdrive:\deploytome'
    }

    It 'executes the installation with the deployment settings' {
        Assert-MockCalled ExecuteInstallation -ParameterFilter {
            (&{$Settings}).somesetting -eq 'some-value'
        }
    }
}

Describe 'Install-DeploymentPackage, with no variables' {

    Setup -Dir pdtemp

    Mock ExtractPackage { }
    Mock ExecuteInstallation { }

    Install-DeploymentPackage `
        -PackageArchive 'somepackage_1.2.3.zip' `
        -Environment 'production' `
        -PackageTargetPath testdrive:\deploytome `
        -PostInstallScript { }

        It 'configures the deployment context with empty settings' {
            Assert-MockCalled ExecuteInstallation -ParameterFilter { $Settings | should not be $null}
            Assert-MockCalled ExecuteInstallation -ParameterFilter { $Settings.Count | should be 0}
        }
}
