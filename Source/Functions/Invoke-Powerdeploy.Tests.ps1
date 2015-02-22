$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\MimicModule.Tests.ps1
. $here\..\TestHelpers.ps1

Describe 'Invoke-Powerdeploy, with a package archive' {

    Context 'given the archive doesn''t exist' {
        Setup -Dir pdtemp

        $result = Capture { 
            Invoke-Powerdeploy `
                -PackageArchive 'testdrive:\somepackage_1.2.3.zip' `
                -Environment 'production' 
        }

        It 'aborts with an error' {
            $result | should not be $null
            $result | select -expand message | should be 'The package specified does not exist: testdrive:\somepackage_1.2.3.zip'
        }
    }

    Context 'given the archive exists' {
        Setup -File 'somepackage_1.2.3.zip' ''

        Mock Import-Module { }
        Mock Set-ExecutionPolicy { }
        Mock CreateRemoteSession { }
        Mock DeployFilesToTarget { }
        Mock Remove-PSSession { }
        Mock GetPackageTempDirectoryAndShareOnTarget { @{ Share = "target-share"; LocalPath = "c:\target-local" }}
        Mock GenerateUniqueDeploymentId { "0xtest" }
        Mock SetCurrentPowerDeployCommandSession { }
        Mock ExecuteCommandInSession { &$ScriptBlock }
        Mock Install-DeploymentPackage { }

        Invoke-Powerdeploy `
            -ComputerName SERVER1 `
            -RemotePackageTargetPath 'c:\mypackages\gibber' `
            -PackageArchive testdrive:\somepackage_1.2.3.zip `
            -Environment production `
            -PostInstallScript { "hello" } 

        It 'deploys the package and module to the deployment staging directory on the target' {
            Assert-MockCalled DeployFilesToTarget -ParameterFilter {
                $DeploymentTempRoot -eq '\\SERVER1\target-share\0xtest' -and `
                $ScriptRoot -eq "$here\.." -and `
                $PackagePath -eq 'testdrive:\somepackage_1.2.3.zip'
            }
        }

        It 'runs stage two installation on the target using the deployed module' {
            Assert-MockCalled Import-Module -ParameterFilter { $Name -eq 'c:\target-local\0xtest\scripts\Powerdeploy.psm1' }
            Assert-MockCalled Install-DeploymentPackage -Exactly 1
        }

        It 'installs the package for the specified environment into the specified target path with the target staging directory' {
            Assert-MockCalled Install-DeploymentPackage -ParameterFilter { 
                $PackageArchive -eq 'c:\target-local\0xtest\package\somepackage_1.2.3.zip' -and `
                $Environment -eq 'production' -and `
                $PackageTargetPath -eq 'c:\mypackages\gibber'
            }
        }

        It 'includes the post installation script in the stage two installation' {
            Assert-MockCalled Install-DeploymentPackage -ParameterFilter {
                &$PostInstallScript -eq 'hello'
            }
        }
    } 

    Describe 'Invoke-Powerdeploy, with ad-hoc variables' {
        Setup -File 'somepackage_1.2.3.zip' ''

        Mock Import-Module { }
        Mock Set-ExecutionPolicy { }
        Mock CreateRemoteSession { }
        Mock DeployFilesToTarget { }
        Mock Remove-PSSession { }
        Mock GetPackageTempDirectoryAndShareOnTarget { @{ Share = "target-share"; LocalPath = "c:\target-local" }}
        Mock SetCurrentPowerDeployCommandSession { }
        Mock ExecuteCommandInSession { &$ScriptBlock }
        Mock Install-DeploymentPackage { }
        Mock GetSettingsFromUri { @{ SomeSetting = 'some-value' } } -ParameterFilter { $uri -eq 'uri://blah/blah' -and $environmentName -eq 'production' -and $computer -eq 'SERVER1' }

        Invoke-Powerdeploy `
            -ComputerName SERVER1 `
            -RemotePackageTargetPath 'c:\mypackages\gibber' `
            -PackageArchive testdrive:\somepackage_1.2.3.zip `
            -Environment production `
            -Variable @{"variable1" = "some ad-hoc value"}

        It 'includes ad-hoc variables as settings when installing' {
            Assert-MockCalled Install-DeploymentPackage -ParameterFilter {
                ($Variable).variable1 | should be 'some ad-hoc value'
            }
        }
    }
}

